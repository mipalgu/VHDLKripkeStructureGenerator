// AsynchronousBlock+generateRunnerComponents.swift
// VHDLKripkeStructureGenerator
// 
// Created by Morgan McColl.
// Copyright © 2023 Morgan McColl. All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 
// 2. Redistributions in binary form must reproduce the above
//    copyright notice, this list of conditions and the following
//    disclaimer in the documentation and/or other materials
//    provided with the distribution.
// 
// 3. All advertising materials mentioning features or use of this
//    software must display the following acknowledgement:
// 
//    This product includes software developed by Morgan McColl.
// 
// 4. Neither the name of the author nor the names of contributors
//    may be used to endorse or promote products derived from this
//    software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// 
// -----------------------------------------------------------------------
// This program is free software; you can redistribute it and/or
// modify it under the above terms or under the terms of the GNU
// General Public License as published by the Free Software Foundation;
// either version 2 of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, see http://www.gnu.org/licenses/
// or write to the Free Software Foundation, Inc., 51 Franklin Street,
// Fifth Floor, Boston, MA  02110-1301, USA.
// 

import Foundation
import VHDLMachines
import VHDLParsing

/// Add state runner component instantiation.
extension AsynchronousBlock {

    /// Generates the runner components for the given state.
    /// - Parameters:
    ///   - state: The state to generate the state runner for.
    ///   - representation: The machine representation to use.
    init?<T>(
        stateRunnerComponentsFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let validExternals = Set(state.externalVariables)
        let readableExternalVariables = machine.externalSignals.filter {
            $0.mode != .output && validExternals.contains($0.name)
        }
        let stateSpace = readableExternalVariables.reduce(1) {
            guard case .signal(let type) = $1.type else {
                fatalError("Cannot discern state space of \($1.type)!")
            }
            return $0 * type.numberOfValues
        }
        let size = maxExecutionSize != nil ? min(stateSpace, maxExecutionSize!) : stateSpace
        if size == maxExecutionSize {
            fatalError("stateSpace of \(stateSpace) exceed maximum execution size of \(size)!")
        }
        let types = readableExternalVariables.map(\.type)
        guard
            let ringletRunner = AsynchronousBlock(
                ringletRunnerInstantiationFor: state, in: representation, variables: types
            ),
            let kripkeGenerator = AsynchronousBlock(
                kripkeGeneratorInstantiationFor: state, in: representation, variables: types
            ),
            let expander = AsynchronousBlock(
                expanderInstantiationFor: state, in: representation, variables: types
            )
        else {
            return nil
        }
        let components = AsynchronousBlock.blocks(blocks: [ringletRunner, kripkeGenerator, expander])
        let lowerIndexes = readableExternalVariables.flatMap { $0.type.lowerTypeIndex }
        let upperIndexes = readableExternalVariables.flatMap { $0.type.upperTypeIndex }
        guard lowerIndexes.count == upperIndexes.count else {
            return nil
        }
        let indexes = zip(lowerIndexes, upperIndexes)
        self = indexes.enumerated().reduce(components) {
            AsynchronousBlock.generate(block: .forLoop(block: ForGenerate(
                label: VariableName(rawValue: "runner_gen\($1.0)")!,
                iterator: VariableName(rawValue: "i\($1.0)")!,
                range: .to(
                    lower: .literal(value: .integer(value: $1.1.0)),
                    upper: .literal(value: .integer(value: $1.1.1))
                ),
                body: $0
            )))
        }
    }

    init?<T>(
        ringletRunnerInstantiationFor state: State, in representation: T, variables: [Type]
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard machine.drivingClock >= 0, machine.drivingClock < machine.clocks.count else {
            return nil
        }
        let clk = machine.clocks[machine.drivingClock]
        let validExternals = Set(state.externalVariables)
        var startIndex = 0
        let preamble = "\(machine.name.rawValue)_"
        var machineSignals = machine.machineSignals
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineSignals += [LocalSignal(type: .natural, name: .ringletCounter)]
        }
        // swiftlint:disable:next line_length
        let variableMapping: [VariableMap] = machine.externalSignals.map { (signal: PortSignal) -> VariableMap in
            let name = VariableReference.variable(reference: .variable(name: signal.name))
            if signal.mode != .output && validExternals.contains(signal.name) {
                let indexes = signal.type.lowerTypeIndex
                let iterators = indexes.map { _ in
                    let newName = VariableName(rawValue: "i\(startIndex)")!
                    startIndex += 1
                    return newName
                }
                return VariableMap(
                    lhs: name,
                    rhs: .expression(value: signal.type.stateAccess(iterators: iterators))
                )
            } else if signal.mode == .input {
                return VariableMap(
                    lhs: name, rhs: .expression(value: .literal(value: signal.type.signalType.defaultValue))
                )
            } else if !validExternals.contains(signal.name) {
                return VariableMap(
                    lhs: name,
                    rhs: .expression(value: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "current_\(preamble)\(signal.name.rawValue)")!
                    ))))
                )
            } else {
                return VariableMap(
                    lhs: name,
                    rhs: .expression(
                        value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "current_\(signal.name.rawValue)")!
                        )))
                    )
                )
            }
        } + machineSignals.map {
            VariableMap(
                lhs: .variable(reference: .variable(name: $0.name)),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "current_\(preamble)\($0.name.rawValue)")!
                    )))
                )
            )
        } + machine.stateVariables.flatMap { state, variables in
            let statePreamble = "\(preamble)STATE_\(state)_"
            return variables.map { (variable: LocalSignal) -> VariableMap in
                VariableMap(
                    lhs: .variable(reference: .variable(name: variable.name)),
                    rhs: .expression(
                        value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "current_\(statePreamble)\(variable.name.rawValue)")!
                        )))
                    )
                )
            }
        }
        let index: Expression
        if variables.isEmpty {
            index = .literal(value: .integer(value: 0))
        } else {
            guard let arrayIndex = Expression(arrayIndexFor: variables) else {
                return nil
            }
            index = arrayIndex
        }
        self = .component(block: ComponentInstantiation(
            label: VariableName(rawValue: "runner_inst")!,
            name: VariableName(rawValue: "\(machine.name)RingletRunner")!,
            port: PortMap(
                variables: [
                    VariableMap(
                        lhs: .variable(reference: .variable(name: clk.name)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: clk.name)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .reset)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: .reset)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .state)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(
                                name: VariableName(rawValue: "STATE_\(state.name.rawValue)")!
                            )
                        )))
                    )
                ] + variableMapping + [
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .previousRinglet)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: .previousRinglet)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .readSnapshotState)),
                        rhs: .expression(value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(
                                reference: .variable(name: .readSnapshotSignal)
                            )),
                            index: .index(value: index)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .writeSnapshotState)),
                        rhs: .expression(value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(
                                reference: .variable(name: .writeSnapshotSignal)
                            )),
                            index: .index(value: index)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .nextState)),
                        rhs: .expression(value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(
                                reference: .variable(name: .targets)
                            )),
                            index: .index(value: index)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .finished)),
                        rhs: .expression(value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(
                                reference: .variable(name: .finished)
                            )),
                            index: .index(value: index)
                        )))
                    )
                ]
            )
        ))
    }

    init?<T>(
        kripkeGeneratorInstantiationFor state: State, in representation: T, variables: [Type]
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard machine.drivingClock >= 0, machine.drivingClock < machine.clocks.count else {
            return nil
        }
        let clk = machine.clocks[machine.drivingClock]
        let index: Expression
        if variables.isEmpty {
            index = .literal(value: .integer(value: 0))
        } else {
            guard let arrayIndex = Expression(arrayIndexFor: variables) else {
                return nil
            }
            index = arrayIndex
        }
        let port = PortMap(variables: [
            VariableMap(
                lhs: .variable(reference: .variable(name: clk.name)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: clk.name))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .readSnapshotSignal)),
                rhs: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .readSnapshots))),
                    index: .index(value: index)
                )))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .writeSnapshotSignal)),
                rhs: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .writeSnapshots))),
                    index: .index(value: index)
                )))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .ringlet)),
                rhs: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "workingRinglets")!
                    ))),
                    index: .index(value: index)
                )))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .pendingState)),
                rhs: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .pendingStates))),
                    index: .index(value: index)
                )))
            )
        ])
        self = .component(block: ComponentInstantiation(
            label: VariableName(rawValue: "generator_inst")!,
            name: VariableName(rawValue: "\(state.name.rawValue)KripkeGenerator")!,
            port: port
        ))
    }

    init?<T>(
        expanderInstantiationFor state: State, in representation: T, variables: [Type]
    ) where T: MachineVHDLRepresentable {
        let index: Expression
        if variables.isEmpty {
            index = .literal(value: .integer(value: 0))
        } else {
            guard let arrayIndex = Expression(arrayIndexFor: variables) else {
                return nil
            }
            index = arrayIndex
        }
        let port = PortMap(variables: [
            VariableMap(
                lhs: .variable(reference: .variable(name: .ringlet)),
                rhs: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "workingRinglets")!
                    ))),
                    index: .index(value: index)
                )))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .vector)),
                rhs: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .ringlets))),
                    index: .index(value: index)
                )))
            )
        ])
        self = .component(block: ComponentInstantiation(
            label: VariableName(rawValue: "expander_inst")!,
            name: VariableName(rawValue: "\(state.name.rawValue)RingletExpander")!,
            port: port
        ))
    }

}

extension VectorSize {

    init(allValuesForType type: SignalType) {
        let numberOfValues = type.numberOfValues
        self = .to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: numberOfValues - 1))
        )
    }

}

extension Type {

    var signalType: SignalType {
        guard case .signal(let type) = self else {
            fatalError("Cannot discern signal type of \(self)!")
        }
        return type
    }

    var lowerTypeIndex: [Int] {
        signalType.lowerTypeIndex
    }

    var upperTypeIndex: [Int] {
        signalType.upperTypeIndex
    }

    func stateAccess(iterators: [VariableName]) -> Expression {
        signalType.stateAccess(iterators: iterators)
    }

}

extension SignalType {

    var lowerTypeIndex: [Int] {
        switch self {
        case .bit, .boolean, .stdLogic, .stdULogic, .natural:
            return [0]
        case .integer:
            return [Int(Int32.min)]
        case .positive:
            return [1]
        case .real:
            fatalError("Unsupported real value found in \(self)!")
        case .ranged(let type):
            return type.lowerTypeIndex
        }
    }

    var upperTypeIndex: [Int] {
        switch self {
        case .bit, .boolean:
            return [1]
        case .stdLogic, .stdULogic:
            return [2]
        case .integer, .natural, .positive:
            return [Int(Int32.max)]
        case .real:
            fatalError("Unsupported real value found in \(self)!")
        case .ranged(let type):
            return type.upperTypeIndex
        }
    }

    func stateAccess(iterators: [VariableName]) -> Expression {
        guard iterators.count == 1 else {
            guard case .ranged(let type) = self else {
                fatalError("Incorrect number of iterators \(iterators.count) to mutate type \(self)!")
            }
            return type.stateAccess(iterators: iterators)
        }
        let iterator = iterators[0]
        switch self {
        case .bit:
            return .reference(variable: .indexed(
                name: Expression.reference(variable: .variable(reference: .variable(name: .bitTypes))),
                index: .index(value: .reference(variable: .variable(reference: .variable(name: iterator))))
            ))
        case .boolean:
            return .reference(variable: .indexed(
                name: Expression.reference(variable: .variable(reference: .variable(name: .booleanTypes))),
                index: .index(value: .reference(variable: .variable(reference: .variable(name: iterator))))
            ))
        case .integer, .natural, .positive:
            return .reference(variable: .variable(reference: .variable(name: iterator)))
        case .real:
            fatalError("Unsupported real value found in \(self)!")
        case .stdLogic, .stdULogic:
            return .reference(variable: .indexed(
                name: Expression.reference(variable: .variable(reference: .variable(name: .stdLogicTypes))),
                index: .index(value: .reference(variable: .variable(reference: .variable(name: iterator))))
            ))
        case .ranged(let type):
            return type.stateAccess(iterators: iterators)
        }
    }

}

extension RangedType {

    var lowerTypeIndex: [Int] {
        switch self {
        case .bitVector(let size), .stdLogicVector(let size), .stdULogicVector(let size):
            guard let numberOfBits = size.size else {
                fatalError("Cannot discern size of vector \(self).")
            }
            return [Int](repeating: 0, count: numberOfBits)
        case .integer(let size):
            guard case .literal(let lit) = size.min, case .integer(let integer) = lit else {
                fatalError("Cannot discern size of integer \(self).")
            }
            return [integer]
        case .signed(let size):
            guard let numberOfBits = size.size else {
                fatalError("Cannot discern size of numeric vector \(self).")
            }
            return [Int(exp2(Double(numberOfBits - 1))) - 1]
        case .unsigned:
            return [0]
        }
    }

    var upperTypeIndex: [Int] {
        switch self {
        case .bitVector(let size):
            guard let numberOfBits = size.size else {
                fatalError("Cannot discern size of vector \(self).")
            }
            return [Int](repeating: 1, count: numberOfBits)
        case .stdLogicVector(let size), .stdULogicVector(let size):
            guard let numberOfBits = size.size else {
                fatalError("Cannot discern size of vector \(self).")
            }
            return [Int](repeating: 2, count: numberOfBits)
        case .integer(let size):
            guard case .literal(let lit) = size.max, case .integer(let integer) = lit else {
                fatalError("Cannot discern size of integer \(self).")
            }
            return [integer]
        case .signed(let size):
            guard let numberOfBits = size.size else {
                fatalError("Cannot discer size of numeric vector \(self).")
            }
            return [Int(exp2(Double(numberOfBits - 1))) - 1]
        case .unsigned(let size):
            guard let numberOfBits = size.size else {
                fatalError("Cannot discer size of numeric vector \(self).")
            }
            return [Int(exp2(Double(numberOfBits))) - 1]
        }
    }

    func stateAccess(iterators: [VariableName]) -> Expression {
        let fn: (Int) -> Expression
        let numberOfIndexes: Int
        switch self {
        case .bitVector(let size), .signed(let size), .unsigned(let size):
            numberOfIndexes = size.size!
            fn = { SignalType.bit.stateAccess(iterators: [iterators[$0]]) }
        case .integer:
            numberOfIndexes = 1
            fn = { SignalType.integer.stateAccess(iterators: [iterators[$0]]) }
        case .stdLogicVector(let size):
            numberOfIndexes = size.size!
            fn = { SignalType.stdLogic.stateAccess(iterators: [iterators[$0]]) }
        case .stdULogicVector(let size):
            numberOfIndexes = size.size!
            fn = { SignalType.stdULogic.stateAccess(iterators: [iterators[$0]]) }
        }
        guard iterators.count == numberOfIndexes else {
            fatalError("Incorrect Number of iterators \(iterators.count) to mutate type \(self).")
        }
        return (0..<numberOfIndexes).map(fn).concatenated
    }

}

extension Expression {

    init?(arrayIndexFor types: [Type]) {
        guard !types.isEmpty else {
            return nil
        }
        let lowerIndexes = types.flatMap { $0.lowerTypeIndex }
        let upperIndexes = types.flatMap { $0.upperTypeIndex }
        guard lowerIndexes.count == upperIndexes.count else {
            return nil
        }
        guard upperIndexes.count > 1 else {
            self = .reference(variable: .variable(reference: .variable(name: VariableName(rawValue: "i0")!)))
            return
        }
        let indexes = zip(lowerIndexes, upperIndexes)
        var currentMultiplier = 1
        self = indexes.enumerated()
        .map {
            let newExpression = Expression.binary(operation: .multiplication(
                lhs: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "i\($0)")!
                ))),
                rhs: .literal(value: .integer(value: currentMultiplier))
            ))
            let difference = $1.1 - $1.0 + 1
            currentMultiplier *= difference
            return newExpression
        }
        .joined { Expression.binary(operation: .addition(lhs: $0, rhs: $1)) }
    }

}
