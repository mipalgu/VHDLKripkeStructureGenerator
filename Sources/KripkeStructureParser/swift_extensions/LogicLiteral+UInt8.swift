// LogicLiteral+UInt8.swift
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

extension String {

    static let swiftExtensions = """
    import Foundation
    import VHDLParsing

    extension LogicLiteral {

        init?(value: UnsafeMutablePointer<UInt8>) {
            self.init(value: value.pointee)
        }

        init?(value: UInt8) {
            switch value {
            case 0:
                self = .low
            case 1:
                self = .high
            case 3:
                self = .highImpedance
            default:
                return nil
            }
        }

    }

    extension SignalLiteral {

        init(value: Bool) {
            self = .boolean(value: value)
        }

        init(value: Int32) {
            self = .integer(value: Int(bigEndian: Int(value)))
        }

        init(value: UInt32) {
            self = .integer(value: Int(bigEndian: Int(value)))
        }

        init(value: Int16) {
            self = .integer(value: Int(bigEndian: Int(value)))
        }

        init(value: UInt16) {
            self = .integer(value: Int(bigEndian: Int(value)))
        }

        init(value: Int8) {
            self = .integer(value: Int(bigEndian: Int(value)))
        }

        init(value: UInt8) {
            self = .integer(value: Int(bigEndian: Int(value)))
        }

    }

    extension BitLiteral {

        init?(value: UnsafeMutablePointer<UInt8>) {
            self.init(value: value.pointee)
        }

        init?(value: UInt8) {
            switch value {
            case 0:
                self = .low
            case 1:
                self = .high
            default:
                return nil
            }
        }

    }

    extension LogicVector {

        init?(value: UnsafeMutablePointer<UInt8>, numberOfBits: Int) {
            guard numberOfBits > 0 else {
                return nil
            }
            let numberOfBytes = Int(ceil(Double(numberOfBits) / 8))
            let pointer = UnsafeMutableBufferPointer(start: value, count: numberOfBytes)
            let array = Array(pointer)
            self.init(value: array, numberOfBits: numberOfBits)
        }

        init?(value: [UInt8], numberOfBits: Int) {
            guard numberOfBits.isMultiple(of: 2), numberOfBits >= 2, value.count > (numberOfBits - 1) / 8 else {
                return nil
            }
            let values = Array(value.reversed())
            let literals = (0..<numberOfBits / 2).compactMap {
                let valueIndex = $0 * 2 / 8
                let byteIndex = $0 * 2 - valueIndex * 8
                let mask = UInt8(exp2(Double(byteIndex))) & UInt8(exp2(Double(byteIndex + 1)))
                return LogicLiteral(value: values[valueIndex] & mask)
            }
            guard literals.count == numberOfBits / 2 else {
                return nil
            }
            self.init(values: literals)
        }

        init?(value: UInt8, numberOfBits: Int) {
            guard numberOfBits.isMultiple(of: 2), numberOfBits >= 2, numberOfBits <= 8 else {
                return nil
            }
            let literals = (0..<numberOfBits / 2).compactMap {
                let mask = UInt8(exp2(Double($0 * 2))) & UInt8(exp2(Double($0 * 2 + 1)))
                return LogicLiteral(value: value & mask)
            }
            guard literals.count == numberOfBits / 2 else {
                return nil
            }
            self.init(values: literals)
        }

    }

    extension BitVector {

        init?(value: UnsafeMutablePointer<UInt8>, numberOfBits: Int) {
            guard numberOfBits > 0 else {
                return nil
            }
            let numberOfBytes = Int(ceil(Double(numberOfBits) / 8))
            let pointer = UnsafeMutableBufferPointer(start: value, count: numberOfBytes)
            let array = Array(pointer)
            self.init(value: array, numberOfBits: numberOfBits)
        }

        init?(value: [UInt8], numberOfBits: Int) {
            guard numberOfBits > 0, value.count > (numberOfBits - 1) / 8 else {
                return nil
            }
            let values = Array(value.reversed())
            let literals = (0..<numberOfBits).compactMap {
                let valueIndex = $0 / 8
                let byteIndex = $0 - valueIndex * 8
                let mask = UInt8(exp2(Double(byteIndex)))
                return BitLiteral(value: values[valueIndex] & mask)
            }
            guard literals.count == numberOfBits else {
                return nil
            }
            self.init(values: literals)
        }

        init?(value: UInt8, numberOfBits: Int) {
            guard numberOfBits <= 8, numberOfBits > 0 else {
                return nil
            }
            let literals = (0..<numberOfBits).compactMap {
                let mask = UInt8(exp2(Double($0)))
                return BitLiteral(value: value & mask)
            }
            guard literals.count == numberOfBits else {
                return nil
            }
            self.init(values: literals)
        }

    }
    """

}
