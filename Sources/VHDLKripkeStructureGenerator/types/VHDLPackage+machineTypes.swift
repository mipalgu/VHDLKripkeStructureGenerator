// VHDLPackage+machineTypes.swift
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

/// Add type package initialisation.
extension VHDLPackage {

    /// Create the type package for a machine representation.
    /// - Parameter representation: The machine to create the package for.
    @inlinable
    init?<T>(typesFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard
            let name = VariableName(rawValue: "\(machine.name.rawValue)Types"),
            let readSnapshot = Record(readSnapshotFor: representation),
            let writeSnapshot = Record(writeSnapshotFor: representation),
            let totalSnapshot = Record(totalSnapshotFor: representation)
        else {
            return nil
        }
        let stateRecords: [[Record]] = machine.states.compactMap {
            guard let writeSnapshot = Record(writeSnapshotFor: $0, in: representation) else {
                return nil
            }
            return [
                Record(readSnapshotFor: $0, in: representation),
                writeSnapshot,
                Record(ringletFor: $0)
            ]
        }
        guard stateRecords.count == machine.states.count else {
            return nil
        }
        let unwrappedStateRecords = stateRecords.flatMap {
            $0.map { HeadStatement.definition(value: .type(value: .record(value: $0))) }
        }
        let stateExecutionTypes = machine.states.flatMap {
            [
                HeadStatement.definition(
                    value: .type(value: .array(value: $0.executionTypes(in: representation)))
                ),
                HeadStatement.definition(value: .type(value: .array(value: ArrayDefinition(
                    name: VariableName(
                        rawValue: "STATE_\($0.name.rawValue)_Ringlets_\(VariableName.rawType.rawValue)"
                    )!,
                    size: [$0.memoryStorage(for: $0, in: representation)],
                    elementType: .signal(type: $0.encodedType(in: representation))
                ))))
            ]

        }
        self.init(
            name: name,
            statements: [
                .definition(value: .type(value: .record(value: readSnapshot))),
                .definition(value: .type(value: .record(value: writeSnapshot))),
                .definition(value: .type(value: .record(value: totalSnapshot)))
            ] + unwrappedStateRecords + stateExecutionTypes + representation.allConstants
        )
    }

}

extension MachineVHDLRepresentable {

    /// Find all constants in the architecture head.
    @inlinable var allConstants: [HeadStatement] {
        self.architectureHead.statements.filter {
            guard case .definition(let def) = $0, case .constant = def else {
                return false
            }
            return true
        }
    }

}
