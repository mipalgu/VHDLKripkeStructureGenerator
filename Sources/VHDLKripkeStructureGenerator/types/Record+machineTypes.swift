// Record+machineTypes.swift
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

/// Add types definitions for machine.
extension Record {

    // swiftlint:disable force_unwrapping

    /// Create the `ReadSnapshot_t` record for a machine.
    /// - Parameter representation: The representation to create the record for.
    @inlinable
    init?<T>(readSnapshotFor representation: T) where T: MachineVHDLRepresentable {
        guard let stateType = representation.stateType else {
            return nil
        }
        let machine = representation.machine
        let preamble = "\(machine.name.rawValue)_"
        let inputs = machine.externalSignals.filter { $0.mode == .input }.map {
            RecordTypeDeclaration(name: $0.name, type: $0.type)
        }
        let outputs = machine.externalSignals.filter { $0.mode != .input }.map {
            RecordTypeDeclaration(
                name: VariableName(pre: preamble, name: $0.name)!,
                type: $0.type
            )
        }
        var machineSignals = machine.machineSignals.map {
            RecordTypeDeclaration(name: VariableName(pre: preamble, name: $0.name)!, type: $0.type)
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineSignals += [
                RecordTypeDeclaration(
                    name: VariableName(pre: preamble, name: .ringletCounter)!, type: .signal(type: .natural)
                )
            ]
        }
        let states = machine.stateVariables.flatMap {
            let statePreamble = preamble + "STATE_\($0)_"
            return $1.map {
                RecordTypeDeclaration(name: VariableName(pre: statePreamble, name: $0.name)!, type: $0.type)
            }
        }
        self.init(name: .readSnapshotType, types: inputs + outputs + machineSignals + states + [
            RecordTypeDeclaration(name: .state, type: .signal(type: stateType)),
            RecordTypeDeclaration(name: .executeOnEntry, type: .signal(type: .boolean))
        ])
    }

    /// Create the `WriteSnapshot_t` record for a machine.
    /// - Parameter representation: The representation to create the record for.
    @inlinable
    init?<T>(writeSnapshotFor representation: T) where T: MachineVHDLRepresentable {
        guard let stateType = representation.stateType else {
            return nil
        }
        let machine = representation.machine
        let preamble = "\(machine.name.rawValue)_"
        let externals = machine.externalSignals.map {
            RecordTypeDeclaration(name: $0.name, type: $0.type)
        }
        var machineSignals = machine.machineSignals.map {
            RecordTypeDeclaration(name: VariableName(pre: preamble, name: $0.name)!, type: $0.type)
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineSignals += [
                RecordTypeDeclaration(
                    name: VariableName(pre: preamble, name: .ringletCounter)!, type: .signal(type: .natural)
                )
            ]
        }
        let stateSignals = machine.stateVariables.flatMap {
            let statePreamble = preamble + "STATE_\($0)_"
            return $1.map {
                RecordTypeDeclaration(name: VariableName(pre: statePreamble, name: $0.name)!, type: $0.type)
            }
        }
        self.init(name: .writeSnapshotType, types: externals + machineSignals + stateSignals + [
            RecordTypeDeclaration(name: .state, type: .signal(type: stateType)),
            RecordTypeDeclaration(name: .nextState, type: .signal(type: stateType)),
            RecordTypeDeclaration(name: .executeOnEntry, type: .signal(type: .boolean))
        ])
    }

    /// Create the `TotalSnapshot_t` record for a machine.
    /// - Parameter representation: The representation to create the record for.
    @inlinable
    init?<T>(totalSnapshotFor representation: T) where T: MachineVHDLRepresentable {
        guard
            let stateType = representation.stateType, let internalStateType = representation.internalStateType
        else {
            return nil
        }
        let machine = representation.machine
        let externals = machine.externalSignals.map { RecordTypeDeclaration(name: $0.name, type: $0.type) }
        let preamble = "\(machine.name.rawValue)_"
        let internalExternals = machine.externalSignals.flatMap {
            let internalSignal = RecordTypeDeclaration(
                name: VariableName(pre: preamble, name: $0.name)!, type: $0.type
            )
            guard $0.mode != .input else {
                return [internalSignal]
            }
            let inputSignal = RecordTypeDeclaration(
                name: VariableName(pre: preamble, name: $0.name, post: "In")!, type: $0.type
            )
            return [internalSignal, inputSignal]
        }
        var machineSignals = machine.machineSignals.flatMap {
            [
                RecordTypeDeclaration(
                    name: VariableName(pre: preamble, name: $0.name)!, type: $0.type
                ),
                RecordTypeDeclaration(
                    name: VariableName(pre: preamble, name: $0.name, post: "In")!, type: $0.type
                )
            ]
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineSignals += [
                RecordTypeDeclaration(
                    name: VariableName(pre: preamble, name: .ringletCounter)!, type: .signal(type: .natural)
                ),
                RecordTypeDeclaration(
                    name: VariableName(pre: preamble, name: .ringletCounter, post: "In")!,
                    type: .signal(type: .natural)
                )
            ]
        }
        let stateSignals = machine.stateVariables.flatMap { state, variable in
            let statePreamble = preamble + "STATE_\(state)_"
            return variable.flatMap {
                [
                    RecordTypeDeclaration(
                        name: VariableName(pre: statePreamble, name: $0.name)!, type: $0.type
                    ),
                    RecordTypeDeclaration(
                        name: VariableName(pre: statePreamble, name: $0.name, post: "In")!, type: $0.type
                    )
                ]
            }
        }
        let controlSignals = [RecordTypeDeclaration].snapshotControlSignals(
            stateType: .signal(type: stateType), internalStateType: internalStateType
        )
        self.init(
            name: .totalSnapshot,
            types: externals + internalExternals + machineSignals + stateSignals + controlSignals
        )
    }

    // swiftlint:enable force_unwrapping

}

/// Add helper properties.
extension MachineVHDLRepresentable {

    /// Get the type of the `internalState` variable.
    @inlinable var internalStateType: Type? {
        self.architectureHead.statements.compactMap {
            guard
                case .definition(let def) = $0, case .signal(let signal) = def, signal.name == .internalState
            else {
                return nil
            }
            return signal.type
        }
        .first
    }

}

/// Add constants.
extension Array where Element == RecordTypeDeclaration {

    /// Create the control signals for the `TotalSnapshot_t` record.
    /// - Parameters:
    ///   - stateType: The type of the state encoding.
    ///   - internalStateType: The type of the internal state encoding.
    /// - Returns: The control signals.
    @inlinable
    static func snapshotControlSignals(stateType: Type, internalStateType: Type) -> [RecordTypeDeclaration] {
        [
            RecordTypeDeclaration(name: .currentStateIn, type: stateType),
            RecordTypeDeclaration(name: .currentStateOut, type: stateType),
            RecordTypeDeclaration(name: .previousRingletIn, type: stateType),
            RecordTypeDeclaration(name: .previousRingletOut, type: stateType),
            RecordTypeDeclaration(name: .internalStateIn, type: internalStateType),
            RecordTypeDeclaration(name: .internalStateOut, type: internalStateType),
            RecordTypeDeclaration(name: .targetStateIn, type: stateType),
            RecordTypeDeclaration(name: .targetStateOut, type: stateType),
            RecordTypeDeclaration(name: .reset, type: .signal(type: .stdLogic)),
            RecordTypeDeclaration(name: .goalInternalState, type: internalStateType),
            RecordTypeDeclaration(name: .finished, type: .signal(type: .boolean)),
            RecordTypeDeclaration(name: .executeOnEntry, type: .signal(type: .boolean)),
            RecordTypeDeclaration(name: .observed, type: .signal(type: .boolean))
        ]
    }

}
