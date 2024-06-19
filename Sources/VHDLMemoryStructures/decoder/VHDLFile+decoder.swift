// VHDLFile+decoder.swift
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
import VHDLParsing

/// Create a generic decoder.
extension VHDLFile {

    /// Create a generic decoder.
    /// 
    /// This initialiser creates a 32-bit decoder that assumes each element within the encoded 32-bit value
    /// contains an enable bit at it's suffix. For example, the element `"0110"` of length 4-bits would be
    /// immediately followed by a 1-bit enable bit `'1'`. The `elementSize` parameter should ignore this
    /// enable bit when calculating the size of each element.
    /// 
    /// For example, consider a 32-bit encoded value with 2 elements
    /// each of size 4-bits. The encoded value may be: `"11011000110000000000000000000000"`. The first element
    /// is `"1101` with enable bit `'1'`, and the second element is `"0001"` with enable bit `'1'`. All other
    /// entries are padding. The decoder will contain a `data` input and 4 outputs named `out0`, `out0en`,
    /// `out1`, and `out1en` representing the decoded elements and their enable bits respectively. Please note
    /// that the element starting at the most-significant bit of the encoded value is considered element 0.
    /// - Parameters:
    ///   - name: The name of the decoder.
    ///   - elements: The number of elements in the decoder.
    ///   - size: The size of each element in the decoder.
    /// - Warning: The `numberOfElements` and `elementSize` parameters must be greater than 0.
    @inlinable
    public init?(decoderName name: VariableName, numberOfElements elements: Int, elementSize size: Int) {
        guard
            let entity = Entity(decoderName: name, numberOfElements: elements, elementSize: size),
            let architecture = Architecture(decoderName: name, numberOfElements: elements, elementSize: size)
        else {
            return nil
        }
        self.init(
            architectures: [architecture],
            entities: [entity],
            includes: [.library(value: .ieee), .include(statement: .stdLogic1164)]
        )
    }

}
