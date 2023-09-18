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
        let ringletRunner = VariableName(rawValue: "\(machine.name.rawValue)RingletRunner")!
        let stateGenerator = VariableName(rawValue: "\(state.name.rawValue)KripkeGenerator")!
        let ringletExpander = VariableName(rawValue: "\(state.name.rawValue)RingletExpander")!
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
        let lowerIndexes = readableExternalVariables.map { $0.type.lowerTypeIndex }
        let upperIndexes = readableExternalVariables.map { $0.type.upperTypeIndex }
        guard lowerIndexes.count == upperIndexes.count else {
            return nil
        }
        let indexes = zip(lowerIndexes, upperIndexes)
        
        return nil
    }

    init?<T>(
        ringletRunnerInstantiationFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard machine.drivingClock >= 0, machine.drivingClock < machine.clocks.count else {
            return nil
        }
        let clk = machine.clocks[machine.drivingClock]
        let validExternals = Set(state.externalVariables)
        var startIndex = 0
        let preamble = "\(machine.name.rawValue)_"
        let componentInstantiation: [Expression] = machine.externalSignals.map {
            if $0.mode != .output && validExternals.contains($0.name) {
                let indexes = $0.type.lowerTypeIndex
                let iterators = indexes.map { _ in
                    let newName = VariableName(rawValue: "i\(startIndex)")!
                    startIndex += 1
                    return newName
                }
                return $0.type.stateAccess(iterators: iterators)
            } else if $0.mode == .input {
                return .literal(value: $0.type.signalType.defaultValue)
            } else if !validExternals.contains($0.name) {
                return .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "current_\(preamble)\($0.name.rawValue)")!
                )))
            } else {
                return .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "current_\($0.name.rawValue)")!
                )))
            }
        } + machine.machineSignals.map {
            .reference(variable: .variable(reference: .variable(
                name: VariableName(rawValue: "current_\(preamble)\($0.name.rawValue)")!
            )))
        } + machine.stateVariables.flatMap { state, variables in
            let statePreamble = "\(preamble)STATE_\(state)_"
            return variables.map { (variable: LocalSignal) -> Expression in
                .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "current_\(statePreamble)\(variable.name.rawValue)")!
                )))
            }
        }
        componentInstantiation.forEach {
            print($0.rawValue)
        }
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
            return [8]
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
            return [Int](repeating: 8, count: numberOfBits)
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
