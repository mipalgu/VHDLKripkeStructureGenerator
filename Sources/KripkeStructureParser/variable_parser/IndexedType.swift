// IndexedType.swift
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

struct IndexedType {

    let record: RecordTypeDeclaration

    let index: VectorIndex

    func implementation<T>(
        state: State, representation: T, type: NodeType
    ) -> (NodeVariable, String) where T: MachineVHDLRepresentable {
        let machineName = representation.entity.name.rawValue
        let stateName = state.name.rawValue
        let addressType = "\(machineName)_STATE_\(stateName)_Raw_t data"
        let variable = NodeVariable(data: self.record, type: type)
        let functionName = "\(machineName)_\(stateName)_\(type.rawValue)_\(self.record.name.rawValue)"
        guard self.index.isAccrossBoundary(state: state, in: representation) else {
            let returnType = self.record.type.signalType.ctype.0.rawValue
            let memoryIndex = Int(
                (Double(self.index.min.integer) / Double(representation.numberOfDataBitsPerAddress))
            )
            let dataIndexOffset = self.index.min.integer - (
                self.index.min.integer % representation.numberOfDataBitsPerAddress
            )
            let indexes = self.index.mutateIndexes { $0 - dataIndexOffset }.asRange
            let leadingZeros = String(repeating: "0", count: indexes[0])
            let trailingZeros = String(
                repeating: "0",
                count: 32 - indexes.count - leadingZeros.count
            )
            let mask = "0b\(leadingZeros)\(String(repeating: "1", count: indexes.count))\(trailingZeros)"
            let shiftAmount = 32 - indexes.count - leadingZeros.count
            return (
                variable,
                """
                \(returnType) \(functionName)(\(addressType))
                {
                    return ((\(returnType)) ((data.data\(memoryIndex) & \(mask)) >> \(shiftAmount)));
                }
                """
            )
        }
        let access = MemoryAccess.getAccess(indexes: self.index, in: representation)
        let variableName = self.record.name.rawValue
        let body = access.map {
            let leadingZeros: String
            if $0.address != 0 {
                leadingZeros = ""
            } else {
                leadingZeros = String(repeating: "0", count: $0.indexes[0])
            }
            let trailingZeros: String
            if $0.address != access[access.count - 1].address {
                trailingZeros = String(
                    repeating: "0", count: 32 - representation.numberOfDataBitsPerAddress
                )
            } else {
                trailingZeros = String(
                    repeating: "0",
                    count: 32 - $0.indexes.count
                )
            }
            let mask = "0b\(leadingZeros)\(String(repeating: "1", count: $0.indexes.count))" +
                trailingZeros
            let shiftAmount = 32 - $0.indexes.count - leadingZeros.count
            return "\(variableName)[\($0.address)] = " +
                "(data.data\($0.address) & \(mask)) >> \(shiftAmount);"
        }
        let functionBody = body.joined(separator: "\n")
        return (
            variable,
            """
            void \(functionName)(\(addressType), uint32_t *\(variableName))
            {
            \(functionBody.indent(amount: 1))
            }
            """
        )
    }

}
