// State+encodedSize.swift
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

/// Add encoding helper methods.
extension State {

    /// Calculate the number of bits required to encode a ringlet for this state.
    /// - Parameter representation: The machine representation to use.
    /// - Returns: The number of bits required to encode a ringlet for this state.
    @inlinable
    func encodedSize<T>(in representation: T) -> Int where T: MachineVHDLRepresentable {
        guard let write = Record(writeSnapshotFor: self, in: representation) else {
            fatalError("Failed to get state encoding for \(self.name)!")
        }
        let read = Record(readSnapshotFor: self, in: representation)
        let writeBits = write.types.filter { $0.name != .nextState }.reduce(0) {
            $0 + $1.type.signalType.encodedBits
        }
        return read.encodedBits + writeBits + representation.machine.numberOfStateBits + 1
    }

    /// The type to encode a ringlet of this state.
    /// - Parameter representation: The machine representation to use.
    /// - Returns: The type of the encoded ringlet for this state.
    @inlinable
    func encodedType<T>(in representation: T) -> SignalType where T: MachineVHDLRepresentable {
        SignalType.ranged(type: .stdLogicVector(size: .to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: self.encodedSize(in: representation) - 1))
        )))
    }

    /// The size of the BRAM structure that stores this state.
    /// - Parameter representation: The machine representation to use.
    /// - Returns: The BRAM size.
    @inlinable
    func memoryStorage<T>(
        for state: State, in representation: T
    ) -> VectorSize where T: MachineVHDLRepresentable {
        .to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(
                value: self.numberOfMemoryAddresses(for: state, in: representation) - 1
            ))
        )
    }

    /// Calculate the number of memory addresses required to store the entire state-space of this state.
    /// - Parameter representation: The machine representation to use.
    /// - Returns: The number of memory addresses.
    @inlinable
    func numberOfMemoryAddresses<T>(
        for state: State, in representation: T
    ) -> Int where T: MachineVHDLRepresentable {
        let numberOfValues: Int = Record(readSnapshotFor: state, in: representation).types.reduce(1) {
            guard case .signal(let type) = $1.type else {
                fatalError("Cannot discern state size for \($1.rawValue)!")
            }
            return $0 * type.numberOfValues
        }
        let size = Double(self.encodedSize(in: representation))
        let stateSize = Double(representation.machine.numberOfStateBits)
        let availableBits = 32.0 - stateSize
        let footprint = size / availableBits
        guard footprint <= 1.0 else {
            let addresses = Int(ceil((size + stateSize) / 32.0))
            return max(1, numberOfValues * addresses)
        }
        let ringletsPerAddress = Int(floor(availableBits / size))
        return max(1, numberOfValues * ringletsPerAddress)
    }

}
