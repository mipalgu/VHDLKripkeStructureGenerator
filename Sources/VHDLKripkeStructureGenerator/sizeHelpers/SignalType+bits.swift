// SignalType+bits.swift
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

/// Add bits.
extension SignalType {

    /// Calculate the number of bits required to represent this type.
    @inlinable var bits: Int {
        switch self {
        case .bit, .boolean, .stdLogic, .stdULogic:
            return 1
        case .integer, .natural, .positive, .real:
            return 32
        case .ranged(let type):
            return type.bits
        }
    }

    /// The number of bits to encode the different values of this type. This will include an additional bit
    /// for logic types as they represent tri-state signals.
    @inlinable var encodedBits: Int {
        switch self {
        case .bit, .boolean, .integer, .natural, .positive, .real:
            return self.bits
        case .stdLogic, .stdULogic:
            return 2
        case .ranged(let type):
            return type.bits
        }
    }

}

/// Add bits.
extension RangedType {

    // swiftlint:disable force_unwrapping

    /// Calculate the number of bits required to represent this type.
    @inlinable var bits: Int {
        switch self {
        case .bitVector(let size), .signed(let size), .unsigned(let size):
            return size.size!
        case .integer(let size):
            guard
                case .literal(let maxLiteral) = size.max,
                case .integer(let maxValue) = maxLiteral,
                case .literal(let minLiteral) = size.min,
                case .integer(let minValue) = minLiteral
            else {
                fatalError("Cannot discern size of \(self)")
            }
            let bits = maxValue.bits.max(other: minValue.bits)
            if minValue < 0 && maxValue >= 0 {
                return bits + 1
            }
            return bits
        case .stdLogicVector(let size), .stdULogicVector(let size):
            return size.size!
        }
    }

    /// The number of bits to encode the different values of this type. This will include an additional bit
    /// for logic types as they represent tri-state signals.
    @inlinable var encodedBits: Int {
        switch self {
        case .bitVector, .signed, .unsigned, .integer:
            return self.bits
        case .stdLogicVector, .stdULogicVector:
            return self.bits * 2
        }
    }

    // swiftlint:enable force_unwrapping

}

/// Add bits.
extension Int {

    /// Calculate the number of bits required to represent self. This is the minimum reqired bits to contain
    /// the value using an extra sign bit for negative numbers.
    @inlinable var bits: Int {
        let calculation = log2(abs(Double(self)))
        if ceil(calculation) == calculation {
            if self < 0 {
                return Int(calculation) + 2
            }
            return Int(calculation) + 1
        }
        if self < 0 {
            return Int(ceil(calculation)) + 1
        }
        return Int(ceil(calculation))
    }

    /// Return the maximum of self and other.
    /// - Parameter other: The other value to compare to.
    /// - Returns: The maximum of self and other.
    @inlinable
    func max(other: Int) -> Int {
        self > other ? self : other
    }

}
