// ArchitectureHead+ringletRunner.swift
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

import VHDLMachines
import VHDLParsing

extension ArchitectureHead {

    init?<T>(ringletRunnerFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let constantSize = VectorSize.downto(
            upper: .literal(value: .integer(value: 2)), lower: .literal(value: .integer(value: 0))
        )
        guard
            let readSnapshot = ConstantSignal(
                name: .readSnapshot,
                type: .ranged(type: .stdLogicVector(size: constantSize)),
                value: .literal(value: .vector(value: .bits(value: BitVector(values: [.high, .low, .high]))))
            ),
            let writeSnapshot = ConstantSignal(
                name: .writeSnapshot,
                type: .ranged(type: .stdLogicVector(size: constantSize)),
                value: .literal(value: .vector(value: .bits(value: BitVector(values: [.high, .high, .low]))))
            ),
            let machineRunnerPort = PortBlock(runnerFor: representation),
            let runnerName = VariableName(rawValue: "\(machine.name.rawValue)MachineRunner")
        else {
            return nil
        }
        let machineSignal = LocalSignal(
            type: .alias(name: .totalSnapshot),
            name: .machine,
            defaultValue: .literal(value: .vector(value: .indexed(
                values: IndexedVector(snapshotDefaultsFor: machine)
            )))
        )
        let tracker = LocalSignal(
            type: .ringletRunnerTracker,
            name: .tracker,
            defaultValue: .literal(value: .vector(value: .bits(value: BitVector(values: [.low, .low]))))
        )
        let size = VectorSize(supporting: machine.states)
        guard let bits = size.size else {
            return nil
        }
        let currentState = LocalSignal(
            type: .ranged(type: .stdLogicVector(size: size)),
            name: .currentState,
            defaultValue: .literal(value: .vector(value: .bits(
                value: BitVector(values: [BitLiteral](repeating: .low, count: bits))
            )))
        )
        let machineRunner = ComponentDefinition(name: runnerName, port: machineRunnerPort)
        self.init(statements: [
            .definition(value: .constant(value: readSnapshot)),
            .definition(value: .constant(value: writeSnapshot)),
            .definition(value: .signal(value: machineSignal)),
            .definition(value: .signal(value: tracker)),
            .definition(value: .constant(value: .waitForStart)),
            .definition(value: .constant(value: .runnerExecuting)),
            .definition(value: .constant(value: .waitForMachineStart)),
            .definition(value: .constant(value: .runnerWaitForFinish)),
            .definition(value: .signal(value: currentState)),
            .definition(value: .component(value: machineRunner))
        ])
    }

}

/// Add tracker for ringlet runner.
extension SignalType {

    /// The type of the tracker signal in the ringlet runner.
    @usableFromInline static let ringletRunnerTracker = SignalType.ranged(type: .stdLogicVector(size: .downto(
        upper: .literal(value: .integer(value: 1)), lower: .literal(value: .integer(value: 0))
    )))

}

/// Add constants for ringlet runner.
extension ConstantSignal {

    // swiftlint:disable force_unwrapping

    /// The `WaitForStart` constant.
    @usableFromInline static let waitForStart = ConstantSignal(
        name: .waitForStart,
        type: .ringletRunnerTracker,
        value: .literal(value: .vector(value: .bits(value: BitVector(values: [.low, .low]))))
    )!

    /// The `Executing` constant.
    @usableFromInline static let runnerExecuting = ConstantSignal(
        name: .executing,
        type: .ringletRunnerTracker,
        value: .literal(value: .vector(value: .bits(value: BitVector(values: [.low, .high]))))
    )!

    /// The `WaitForMachineStart` constant.
    @usableFromInline static let waitForMachineStart = ConstantSignal(
        name: .waitForMachineStart,
        type: .ringletRunnerTracker,
        value: .literal(value: .vector(value: .bits(value: BitVector(values: [.high, .low]))))
    )!

    /// The `WaitForFinish` constant.
    @usableFromInline static let runnerWaitForFinish = ConstantSignal(
        name: .waitForFinish,
        type: .ringletRunnerTracker,
        value: .literal(value: .vector(value: .bits(value: BitVector(values: [.high, .high]))))
    )!

    // swiftlint:enable force_unwrapping

}

extension IndexedVector {

    init(snapshotDefaultsFor machine: Machine) {
        let externals = machine.externalSignals.flatMap { (signal: PortSignal) -> [IndexedValue] in
            guard case .signal(let type) = signal.type else {
                fatalError(
                    "Cannot create a verifiable entity from a machine with custom types. Failed " +
                    "to create default values for \(signal.type) in external signal \(signal.name)"
                )
            }
            var declarations: [IndexedValue] = []
            declarations.append(IndexedValue(
                index: .index(value: .reference(variable: .variable(name: signal.name))),
                value: type.defaultValue
            ))
            declarations.append(IndexedValue(
                index: .index(value: .reference(variable: .variable(name: VariableName(
                    rawValue: "\(machine.name.rawValue)_\(signal.name.rawValue)"
                // swiftlint:disable:next force_unwrapping
                )!))),
                value: type.defaultValue
            ))
            if signal.mode == .output {
                declarations.append(IndexedValue(
                    index: .index(value: .reference(variable: .variable(name: VariableName(
                        rawValue: "\(machine.name.rawValue)_\(signal.name.rawValue)In"
                    // swiftlint:disable:next force_unwrapping
                    )!))),
                    value: type.defaultValue
                ))
            }
            return declarations
        }
        let machineVariables = machine.machineSignals.flatMap { (signal: LocalSignal) -> [IndexedValue] in
            guard case .signal(let type) = signal.type else {
                fatalError(
                    "Cannot create a verifiable entity from a machine with custom types. Failed " +
                    "to create default values for \(signal.type) in external signal \(signal.name)"
                )
            }
            return [
                IndexedValue(
                    index: .index(value: .reference(variable: .variable(name: VariableName(
                        rawValue: "\(machine.name.rawValue)_\(signal.name.rawValue)"
                    // swiftlint:disable:next force_unwrapping
                    )!))),
                    value: type.defaultValue
                ),
                IndexedValue(
                    index: .index(value: .reference(variable: .variable(name: VariableName(
                        rawValue: "\(machine.name.rawValue)_\(signal.name.rawValue)In"
                    // swiftlint:disable:next force_unwrapping
                    )!))),
                    value: type.defaultValue
                )
            ]
        }
        let stateVariables = machine.states.flatMap { (state: State) -> [IndexedValue] in
            state.signals.flatMap { (signal: LocalSignal) -> [IndexedValue] in
                guard case .signal(let type) = signal.type else {
                    fatalError(
                        "Cannot create a verifiable entity from a machine with custom types. Failed " +
                        "to create default values for \(signal.type) in external signal \(signal.name)"
                    )
                }
                return [
                    IndexedValue(
                        index: .index(value: .reference(variable: .variable(name: VariableName(
                            rawValue: "\(machine.name.rawValue)_STATE_\(state.name.rawValue)_" +
                                "\(signal.name.rawValue)"
                        // swiftlint:disable:next force_unwrapping
                        )!))),
                        value: type.defaultValue
                    ),
                    IndexedValue(
                        index: .index(value: .reference(variable: .variable(name: VariableName(
                            rawValue: "\(machine.name.rawValue)_STATE_\(state.name.rawValue)_" +
                                "\(signal.name.rawValue)In"
                        // swiftlint:disable:next force_unwrapping
                        )!))),
                        value: type.defaultValue
                    )
                ]
            }
        }
        let stateSize = VectorSize(supporting: machine.states)
        self.init(
            defaultSnapshotForStateSize: stateSize,
            externals: externals,
            machineSignals: machineVariables,
            stateSignals: stateVariables
        )
    }

    init(
        defaultSnapshotForStateSize stateSize: VectorSize,
        externals: [IndexedValue],
        machineSignals: [IndexedValue],
        stateSignals: [IndexedValue]
    ) {
        let currentStateIn = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .currentStateIn))),
            value: SignalType.ranged(type: RangedType.stdLogicVector(size: stateSize)).defaultValue
        )
        let currentStateOut = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .currentStateOut))),
            value: SignalType.ranged(type: RangedType.stdLogicVector(size: stateSize)).defaultValue
        )
        let previousRingletIn = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .previousRingletIn))),
            value: SignalType.ranged(type: RangedType.stdLogicVector(size: stateSize)).defaultValue
        )
        let previousRingletOut = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .previousRingletOut))),
            value: SignalType.ranged(type: RangedType.stdLogicVector(size: stateSize)).defaultValue
        )
        let internalStateIn = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .internalStateIn))),
            value: .reference(variable: .variable(name: .readSnapshot))
        )
        let internalStateOut = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .internalStateOut))),
            value: .reference(variable: .variable(name: .readSnapshot))
        )
        let targetStateIn = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .targetStateIn))),
            value: SignalType.ranged(type: RangedType.stdLogicVector(size: stateSize)).defaultValue
        )
        let targetStateOut = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .targetStateOut))),
            value: SignalType.ranged(type: RangedType.stdLogicVector(size: stateSize)).defaultValue
        )
        let reset = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .reset))),
            value: SignalType.stdLogic.defaultValue
        )
        let goalInternalState = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .goalInternalState))),
            value: .reference(variable: .variable(name: .writeSnapshot))
        )
        let finished = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .finished))),
            value: SignalLiteral.boolean(value: true)
        )
        let executeOnEntry = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .executeOnEntry))),
            value: .boolean(value: true)
        )
        let observed = IndexedValue(
            index: .index(value: .reference(variable: .variable(name: .observed))),
            value: .boolean(value: false)
        )
        self.init(values: externals + machineSignals + stateSignals + [
            currentStateIn,
            currentStateOut,
            previousRingletIn,
            previousRingletOut,
            internalStateIn,
            internalStateOut,
            targetStateIn,
            targetStateOut,
            reset,
            goalInternalState,
            finished,
            executeOnEntry,
            observed
        ])
    }

}

extension SignalType {

    var defaultValue: SignalLiteral {
        SignalLiteral.default(for: self)
    }

}
