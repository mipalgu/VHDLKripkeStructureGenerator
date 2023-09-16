// State+numberOfStates.swift
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

/// Add helpers for calculating state explosion.
extension State {

    /// Calculate the maxmimum state-space of this state.
    /// - Parameter representation: The machine representation to use.
    /// - Returns: The maximum number of Kripke states this state can produce.
    @inlinable
    func numberOfStates<T>(in representation: T) -> Int? where T: MachineVHDLRepresentable {
        guard let write = Record(writeSnapshotFor: self, in: representation) else {
            return nil
        }
        let writeSize = write.types.map {
            guard case .signal(let type) = $0.type else {
                fatalError("Failed to discern size of \($0.type)!")
            }
            return type.numberOfValues
        }
        .reduce(1, *)
        let readSize = Record(readSnapshotFor: self, in: representation).types.map {
            guard case .signal(let type) = $0.type else {
                fatalError("Failed to discern size of \($0.type)!")
            }
            return type.numberOfValues
        }
        .reduce(1, *)
        return writeSize * readSize
    }

    /// Calculate the maxmimum possible state explosion from a single ringlet.
    /// - Parameter representation: The representation of the machine to use.
    /// - Returns: The maxmimum number of states a ringlet can produce in this state.
    @inlinable
    func numberOfStatesForRinglet<T>(in representation: T) -> Int where T: MachineVHDLRepresentable {
        let validSignals = Set(self.externalVariables)
        let externals = representation.machine.externalSignals.filter {
            $0.mode != .output && validSignals.contains($0.name)
        }
        return externals.reduce(1) {
            guard case .signal(let type) = $1.type else {
                fatalError("Failed to discern type size in \($1.type)!")
            }
            return $0 * type.numberOfUnresolvedValues
        }
    }

    /// Create the execution array for this state.
    /// - Parameter representation: The representation of the machine to use.
    /// - Parameter maxExecutionSize: The maximum number of machines executing in parallel.
    /// - Returns: The array definition of the execution type.
    @inlinable
    func executionTypes<T>(
        in representation: T, maxExecutionSize: Int? = nil
    ) -> ArrayDefinition where T: MachineVHDLRepresentable {
        let numberOfStates = self.numberOfStatesForRinglet(in: representation)
        let size = maxExecutionSize.map { min($0, numberOfStates) } ?? numberOfStates
        // swiftlint:disable:next force_unwrapping
        let name = VariableName(pre: "\(self.name.rawValue)_", name: .stateExecutionType)!
        let type = self.encodedType(in: representation)
        return ArrayDefinition(
            name: name,
            size: [
                .to(
                    lower: .literal(value: .integer(value: 0)),
                    upper: .literal(value: .integer(value: max(0, size - 1)))
                )
            ],
            elementType: .signal(type: type)
        )
    }

}
