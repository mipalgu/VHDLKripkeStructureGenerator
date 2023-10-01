// Record+bits.swift
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

import VHDLParsing

/// Add bit claculation helpers.
extension Record {

    /// The minimum number of bits required to represent the entire record.
    @inlinable var bits: Int {
        self.types.reduce(0) {
            guard case .signal(let type) = $1.type else {
                fatalError("Failed to find size of type \($1.type)!")
            }
            return $0 + type.bits
        }
    }

    /// The minimum number of bits required to represent the entire encoded version of the record.
    @inlinable var encodedBits: Int {
        self.types.reduce(0) {
            guard case .signal(let type) = $1.type else {
                fatalError("Failed to find size of type \($1.type)!")
            }
            return $0 + type.encodedBits
        }
    }

    func bitsIndex(for name: VariableName, isDownto: Bool = false) -> VectorIndex? {
        var startIndex = isDownto ? max(0, self.bits - 1) : 0
        return self.types.lazy.compactMap {
            let numberOfBits = $0.type.bits
            defer {
                if isDownto {
                    startIndex -= numberOfBits
                } else {
                    startIndex += numberOfBits
                }
            }
            guard $0.name == name else {
                return nil
            }
            guard numberOfBits <= 1 else {
                guard !isDownto else {
                    return VectorIndex.range(value: .downto(
                        upper: .literal(value: .integer(value: startIndex)),
                        lower: .literal(value: .integer(value: startIndex - numberOfBits + 1))
                    ))
                }
                return VectorIndex.range(value: .to(
                    lower: .literal(value: .integer(value: startIndex)),
                    upper: .literal(value: .integer(value: startIndex + numberOfBits - 1))
                ))
            }
            return .index(value: .literal(value: .integer(value: startIndex)))
        }
        .first
    }

}
