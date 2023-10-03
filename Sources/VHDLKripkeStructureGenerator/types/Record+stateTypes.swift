// Record+stateTypes.swift
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

/// Add state types.
extension Record {

    // swiftlint:disable force_unwrapping

    /// Create the read snapshot type for a state.
    /// - Parameters:
    ///   - state: The state to create the read snapshot for.
    ///   - representation: The machine that owns the state.
    @inlinable
    init<T>(readSnapshotFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let stateExternals = Set(state.externalVariables)
        let validExternals = machine.externalSignals.filter {
            $0.mode != .input || stateExternals.contains($0.name)
        }
        let preamble = "\(machine.name.rawValue)_"
        let externals = validExternals.map {
            let name = $0.mode == .input ? $0.name : VariableName(pre: preamble, name: $0.name)!
            return RecordTypeDeclaration(name: name, type: $0.type)
        }
        let machineSignals = machine.machineSignals.map {
            RecordTypeDeclaration(name: VariableName(pre: preamble, name: $0.name)!, type: $0.type)
        }
        var stateSignals = machine.states.flatMap {
            let statePreamble = "\(preamble)STATE_\($0.name.rawValue)_"
            return $0.signals.map {
                RecordTypeDeclaration(name: VariableName(pre: statePreamble, name: $0.name)!, type: $0.type)
            }
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            stateSignals.append(RecordTypeDeclaration(
                name: VariableName(pre: preamble, name: .ringletCounter)!, type: .signal(type: .natural)
            ))
        }
        let typeName = VariableName(pre: "\(state.name.rawValue)_", name: .readSnapshotType)!
        self.init(
            name: typeName,
            types: externals + machineSignals + stateSignals + [
                RecordTypeDeclaration(name: .executeOnEntry, type: .signal(type: .boolean))
            ]
        )
    }

    /// Create the write snapshot type for a state.
    /// - Parameters:
    ///   - state: The state to create the write snapshot for.
    ///   - representation: The machine that owns the state.
    @inlinable
    init?<T>(writeSnapshotFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        guard let stateType = representation.stateType else {
            return nil
        }
        let machine = representation.machine
        let stateExternals = Set(state.externalVariables)
        let validExternals = machine.externalSignals.filter { $0.mode != .input }
        let preamble = "\(machine.name.rawValue)_"
        let externals = validExternals.map {
            let name = stateExternals.contains($0.name) ? $0.name :
                VariableName(pre: preamble, name: $0.name)!
            return RecordTypeDeclaration(name: name, type: $0.type)
        }
        let machineSignals = machine.machineSignals.map {
            RecordTypeDeclaration(name: VariableName(pre: preamble, name: $0.name)!, type: $0.type)
        }
        var stateSignals = machine.states.flatMap {
            let statePreamble = "\(preamble)STATE_\($0.name.rawValue)_"
            return $0.signals.map {
                RecordTypeDeclaration(name: VariableName(pre: statePreamble, name: $0.name)!, type: $0.type)
            }
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            stateSignals.append(RecordTypeDeclaration(
                name: VariableName(pre: preamble, name: .ringletCounter)!, type: .signal(type: .natural)
            ))
        }
        let typeName = VariableName(pre: "\(state.name.rawValue)_", name: .writeSnapshotType)!
        self.init(
            name: typeName,
            types: externals + machineSignals + stateSignals + [
                RecordTypeDeclaration(name: .nextState, type: .signal(type: stateType)),
                RecordTypeDeclaration(name: .executeOnEntry, type: .signal(type: .boolean))
            ]
        )
    }

    /// Create the ringlet type for a state.
    /// - Parameter state: The state to create the ringlet for.
    @inlinable
    init(ringletFor state: State) {
        let typeName = VariableName(pre: "\(state.name.rawValue)_", name: .ringletType)!
        let preamble = "\(state.name.rawValue)_"
        let readSnapshot = VariableName(pre: preamble, name: .readSnapshotType)!
        let writeSnapshot = VariableName(pre: preamble, name: .writeSnapshotType)!
        self.init(
            name: typeName,
            types: [
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "readSnapshot")!, type: .alias(name: readSnapshot)
                ),
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "writeSnapshot")!, type: .alias(name: writeSnapshot)
                ),
                RecordTypeDeclaration(name: .observed, type: .signal(type: .boolean))
            ]
        )
    }

    // swiftlint:enable force_unwrapping

}
