// VectorIndex+accrossBoundary.swift
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

extension VectorIndex {

    var asRange: [Int] {
        switch self {
        case .index(let index):
            return [index.integer]
        case .others:
            fatalError("Does not support others!")
        case .range(let size):
            return Array(size.min.integer...size.max.integer)
        }
    }

    var count: Int {
        self.asRange.count
    }

    var max: Expression {
        switch self {
        case .index(let index):
            return index
        case .others:
            fatalError("Does not support others!")
        case .range(let size):
            return size.max
        }
    }

    var min: Expression {
        switch self {
        case .index(let index):
            return index
        case .others:
            fatalError("Does not support others!")
        case .range(let size):
            return size.min
        }
    }

    func isAccrossBoundary<T>(state: State, in representation: T) -> Bool where T: MachineVHDLRepresentable {
        switch self {
        case .index:
            return false
        case .others:
            fatalError("Does not support others!")
        case .range(let size):
            let dataBits = representation.numberOfDataBitsPerAddress
            return size.min.integer / dataBits != size.max.integer / dataBits
        }
    }

    func mutateIndexes(_ f: @escaping (Int) -> Int) -> VectorIndex {
        switch self {
        case .index(let index):
            return .index(value: .literal(value: .integer(value: f(index.integer))))
        case .others:
            fatalError("Does not support others!")
        case .range(let size):
            return .range(value: VectorSize.to(
                lower: .literal(value: .integer(value: f(size.min.integer))),
                upper: .literal(value: .integer(value: f(size.max.integer)))
            ))
        }
    }

}

extension MachineVHDLRepresentable {

    var numberOfDataBitsPerAddress: Int {
        // swiftlint:disable:next force_unwrapping
        32 - self.numberOfStateBits! - 1
    }

}
