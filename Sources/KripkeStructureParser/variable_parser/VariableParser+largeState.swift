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

    init<T>(
        largeState state: State, in representation: T, numberOfAddresses: Int
    ) where T: MachineVHDLRepresentable {
        let addressType = "uint32_t data[\(numberOfAddresses)]"
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let machineName = representation.entity.name.rawValue
        let stateName = state.name.rawValue
        let readSnapshotDefinitions = readSnapshot.types.map {
            (
                NodeVariable(data: $0, type: .read),
                "\($0.type.signalType.ctype.0.rawValue) \(machineName)_\(stateName)_READ_" +
                    "\($0.name.rawValue)(\(addressType));"
            )
        }
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let writeSnapshotDefinitions = writeSnapshot.types.filter { $0.name != .nextState }.map {
            (
                NodeVariable(data: $0, type: .write),
                "\($0.type.signalType.ctype.0.rawValue) \(machineName)_\(stateName)_WRITE_" +
                    "\($0.name.rawValue)(\(addressType));"
            )
        }
        let readSnapshotImplementations = readSnapshot.encodedIndexes.map {
            let variable = NodeVariable(data: $0.0, type: .read)
            // let functionName = "\(machineName)_\(stateName)_READ_\($0.name.rawValue)"
            // let returnType = $0.type.signalType.ctype.0.rawValue
            // guard $1.isAccrossBoundary(state: state, in: representation) else {
            //     let memoryIndex = Int(
            //         (Double($1.min.integer) / Double(representation.numberOfDataBitsPerAddress)).rounded(.up)
            //     )
            //     let dataIndexOffset = $1.min.integer % representation.numberOfDataBitsPerAddress
            //     let indexes = $1.mutateIndexes { $0 - dataIndexOffset }.asRange
            //     let trailingZeros = String(
            //         repeating: "0",
            //         count: representation.numberOfDataBitsPerAddress - indexes.count - indexes[0]
            //     )
            //     let leadingZeros = String(repeating: "0", count: indexes[0])
            //     let mask = "0b\(leadingZeros)\(String(repeating: "1", count: indexes.count))\(trailingZeros)"
            //     let shiftAmount = 32 - indexes[indexes.count - 1]
            //     return (
            //         variable,
            //         """
            //         \(returnType) \(functionName)(\(addressType))
            //         {
            //             const uint32_t value = (data[\(memoryIndex)] & \(mask)) >> \(shiftAmount);
            //             return ((\(returnType)) (value));
            //         }
            //         """
            //     )
            // }
            // let lowerMemoryIndex = Int(
            //     (Double($1.min.integer) / Double(representation.numberOfDataBitsPerAddress)).rounded(.up)
            // )
            // let upperMemoryIndex = Int(
            //     (Double($1.max.integer) / Double(representation.numberOfDataBitsPerAddress)).rounded(.up)
            // )
            // let memoryIndexes = lowerMemoryIndex...upperMemoryIndex
            return (variable, "")
        }
        let writeSnapshotImplementations = writeSnapshot.encodedIndexes.map {
            (NodeVariable(data: $0.0, type: .write), "")
        }
        self.init(
            definitions: Dictionary(uniqueKeysWithValues: readSnapshotDefinitions + writeSnapshotDefinitions),
            functions: Dictionary(uniqueKeysWithValues: readSnapshotImplementations + writeSnapshotImplementations)
        )
    }

}
