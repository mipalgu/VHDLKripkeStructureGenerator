// Type+encodedType.swift
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

extension Type {

    @inlinable public var signalType: SignalType {
        guard case .signal(let type) = self else {
            fatalError("Cannot discern signal type of \(self)!")
        }
        return type
    }

    public init?(encodedType: Type) {
        guard case .signal(let type) = encodedType else {
            return nil
        }
        self = .signal(type: SignalType(encodedType: type))
    }

}

extension SignalType {

    public static let logicVector2 = SignalType.ranged(type: .stdLogicVector(
        size: .downto(upper: .literal(value: .integer(value: 1)), lower: .literal(value: .integer(value: 0)))
    ))

    public init(encodedType: SignalType) {
        switch encodedType {
        case .bit, .boolean:
            self = .stdLogic
        case .integer, .natural, .positive, .real:
            self = SignalType.logicVector32
        case .stdLogic, .stdULogic:
            self = .logicVector2
        case .ranged(let type):
            self = .ranged(type: RangedType(encodedType: type))
        }
    }

}

extension RangedType {

    public init(encodedType: RangedType) {
        switch encodedType {
        case .bitVector(let size), .signed(let size), .unsigned(let size):
            self = .stdLogicVector(size: size)
        case .integer:
            self = .stdLogicVector(
                size: .downto(
                    upper: .literal(value: .integer(value: max(0, encodedType.bits - 1))),
                    lower: .literal(value: .integer(value: 0))
                )
            )
        case .stdLogicVector(let size), .stdULogicVector(let size):
            self = .stdLogicVector(
                size: .downto(
                    upper: .literal(value: .integer(value: max(0, size.size! * 2 - 1))),
                    lower: .literal(value: .integer(value: 0))
                )
            )
        }
    }

}
