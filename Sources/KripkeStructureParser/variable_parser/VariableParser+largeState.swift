// VariableParser+largeState.swift
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

import Utilities
import VHDLMachines
import VHDLParsing

extension VariableParser {

    init<T>(largeState state: State, in representation: T) where T: MachineVHDLRepresentable {
        self.init(
            definitions: Dictionary(largeDefinitionsFor: state, in: representation),
            functions: Dictionary(largeImplementationsFor: state, in: representation)
        )
    }

}

extension Dictionary where Key == NodeVariable, Value == String {

    init<T>(largeDefinitionsFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let rawType = "\(representation.entity.name)_STATE_\(state.name)_Raw_t"
        let addressType = "\(rawType) data"
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let machineName = representation.entity.name.rawValue
        let stateName = state.name.rawValue
        let readSnapshotDefinitions = readSnapshot.types.map {
            let variable = NodeVariable(data: $0, type: .read)
            guard $0.type.signalType.encodedBits <= representation.numberOfDataBitsPerAddress else {
                return (
                    variable,
                    "void \(machineName)_\(stateName)_READ_\($0.name.rawValue)(\(addressType), " +
                        "uint32_t *\($0.name.rawValue));"
                )
            }
            return (
                variable,
                "\($0.type.signalType.ctype.0.rawValue) \(machineName)_\(stateName)_READ_" +
                    "\($0.name.rawValue)(\(addressType));"
            )
        }
        let writeSnapshotDefinitions = writeSnapshot.types.filter { $0.name != .nextState }.map {
            let variable = NodeVariable(data: $0, type: .write)
            guard $0.type.signalType.encodedBits <= representation.numberOfDataBitsPerAddress else {
                return (
                    variable,
                    "void \(machineName)_\(stateName)_WRITE_\($0.name.rawValue)(\(addressType), " +
                        "uint32_t *\($0.name.rawValue));"
                )
            }
            return (
                variable,
                "\($0.type.signalType.ctype.0.rawValue) \(machineName)_\(stateName)_WRITE_" +
                    "\($0.name.rawValue)(\(addressType));"
            )
        } + [
            (
                NodeVariable(
                    data: RecordTypeDeclaration(
                        name: .nextState, type: .signal(type: representation.stateType!)
                    ),
                    type: .write
                ),
                "uint32_t \(machineName)_\(stateName)_WRITE_nextState(\(addressType));"
            )
        ]
        self.init(uniqueKeysWithValues: readSnapshotDefinitions + writeSnapshotDefinitions)
    }

    init<T>(largeImplementationsFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let readSnapshotImplementations = readSnapshot.largeTypeImplementations(
            ignoring: [],
            state: state,
            representation: representation,
            type: .read,
            previousRecordIndexCount: 0
        )
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let writeSnapshotImplementations = writeSnapshot.largeTypeImplementations(
            ignoring: [.nextState],
            state: state,
            representation: representation,
            type: .write,
            previousRecordIndexCount: readSnapshot.encodedBits
        )
        self.init(
            uniqueKeysWithValues: readSnapshotImplementations + writeSnapshotImplementations
        )
    }

}

extension Record {

    func largeTypeImplementations<T>(
        ignoring: Set<VariableName>,
        state: State,
        representation: T,
        type: NodeType,
        previousRecordIndexCount count: Int
    ) -> [(NodeVariable, String)] where T: MachineVHDLRepresentable {
        self.encodedIndexes(ignoring: ignoring)
            .map { IndexedType(record: $0, index: $1.mutateIndexes { $0 + count }) }
            .map { $0.implementation(state: state, representation: representation, type: type) }
    }

}
