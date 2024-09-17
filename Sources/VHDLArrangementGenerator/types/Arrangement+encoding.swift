// Arrangement+encoding.swift
// VHDLKripkeStructureGenerator
// 
// Created by Morgan McColl.
// Copyright © 2024 Morgan McColl. All rights reserved.
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

import VHDLMachines
import VHDLParsing

extension ArrangementVHDLRepresentable {

    var readSnapshot: Record {
        let externals = self.arrangement.externalSignals.filter { $0.mode != .output }.map {
            RecordTypeDeclaration(name: $0.name, type: $0.type)
        }
        let globals = self.arrangement.signals.map {
            RecordTypeDeclaration(
                name: VariableName(rawValue: "\(self.name)_\($0.name)")!,
                type: $0.type
            )
        }
        let machineSignals = self.arrangement.machines
            .sorted { $0.key.name < $1.key.name }.flatMap { key, value in
            let name = key.name
            let machine = value.machine
            let snapshots = machine.externalSignals.filter { $0.mode == .output }.map {
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_\($0.name)")!, type: $0.type
                )
            }
            let machineSignals = machine.machineSignals.map {
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_\($0.name)")!,
                    type: $0.type
                )
            }
            let stateSignals = machine.states.flatMap { state in
                state.signals.map {
                    RecordTypeDeclaration(
                        name: VariableName(rawValue: "\(self.name)_\(name)_STATE_\(state.name)_\($0.name)")!,
                        type: $0.type
                    )
                }
            }
            let stateSize = BitLiteral.bitsRequired(for: max(machine.states.count - 1, 1))!
            let stateEncoding = SignalType.ranged(type: .stdLogicVector(size: .downto(
                upper: .literal(value: .integer(value: stateSize - 1)),
                lower: .literal(value: .integer(value: 0))
            )))
            let snapshotEncoding = [
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_state")!,
                    type: .signal(type: stateEncoding)
                ),
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_executeOnEntry")!,
                    type: .signal(type: .stdLogic)
                )
            ]
            return snapshots + machineSignals + stateSignals + snapshotEncoding
        }
        return Record(
            name: VariableName(rawValue: "\(self.name)ReadSnapshot_t")!,
            types: externals + globals + machineSignals
        )
    }

    var writeSnapshot: Record {
        let externals = self.arrangement.externalSignals.filter { $0.mode != .input }.map {
            RecordTypeDeclaration(name: $0.name, type: $0.type)
        }
        let globals = self.arrangement.signals.map {
            RecordTypeDeclaration(
                name: VariableName(rawValue: "\(self.name)_\($0.name)")!,
                type: $0.type
            )
        }
        let machineSignals = self.arrangement.machines
            .sorted { $0.key.name < $1.key.name }.flatMap { key, value in
            let name = key.name
            let machine = value.machine
            let machineSignals = machine.machineSignals.map {
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_\($0.name)")!,
                    type: $0.type
                )
            }
            let stateSignals = machine.states.flatMap { state in
                state.signals.map {
                    RecordTypeDeclaration(
                        name: VariableName(rawValue: "\(self.name)_\(name)_STATE_\(state.name)_\($0.name)")!,
                        type: $0.type
                    )
                }
            }
            let stateSize = BitLiteral.bitsRequired(for: max(machine.states.count - 1, 1))!
            let stateEncoding = SignalType.ranged(type: .stdLogicVector(size: .downto(
                upper: .literal(value: .integer(value: stateSize - 1)),
                lower: .literal(value: .integer(value: 0))
            )))
            let snapshotEncoding = [
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_state")!,
                    type: .signal(type: stateEncoding)
                ),
                RecordTypeDeclaration(
                    name: VariableName(rawValue: "\(self.name)_\(name)_executeOnEntry")!,
                    type: .signal(type: .stdLogic)
                )
            ]
            return machineSignals + stateSignals + snapshotEncoding
        }
        return Record(
            name: VariableName(rawValue: "\(self.name)WriteSnapshot_t")!,
            types: externals + globals + machineSignals
        )
    }

    /// The number of bits required to encode the arrangement.
    var encodedBits: Int {
        readSnapshot.encodedBits + writeSnapshot.encodedBits - 2 - 2 * self.arrangement.machines.reduce(0) {
            $0 + (BitLiteral.bitsRequired(for: $1.value.machine.states.count - 1) ?? 1)
        }
    }

    /// The type of the encoded arrangement.
    var encodedType: SignalType {
        SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: self.encodedBits - 1)),
            lower: .literal(value: .integer(value: 0))
        )))
    }

}
