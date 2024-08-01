// SignalType+defaultValue.swift
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

import VHDLParsing

extension SignalType {

    var defaultValueCreation: String {
        switch self {
        case .bit:
            return "SignalLiteral.bit(value: .low)"
        case .boolean:
            return "SignalLiteral.boolean(value: false)"
        case .integer, .natural:
            return "SignalLiteral.integer(value: 0)"
        case .positive:
            return "SignalLiteral.integer(value: 1)"
        case .real:
            return "SignalLiteral.decimal(value: 0.0)"
        case .stdLogic, .stdULogic:
            return "SignalLiteral.logic(value: .low)"
        case .ranged(let type):
            switch type {
            case .bitVector(let size), .signed(let size), .unsigned(let size):
                return "SignalLiteral.vector(value: .bits(value: BitVector(values: " +
                    "[BitLiteral](repeating: .low, count: \(size.size!)))))"
            case .stdLogicVector(let size), .stdULogicVector(let size):
                return "SignalLiteral.vector(value: .logics(value: LogicVector(values: " +
                    "[LogicLiteral](repeating: .low, count: \(size.size!)))))"
            case .integer:
                return "SignalLiteral.integer(value: 0)"
            }
        }
    }

}

extension SignalLiteral {

    var defaultValueCreation: String {
        switch self {
        case .bit:
            return SignalType.bit.defaultValueCreation
        case .boolean:
            return SignalType.boolean.defaultValueCreation
        case .decimal:
            return SignalType.real.defaultValueCreation
        case .integer:
            return SignalType.integer.defaultValueCreation
        case .logic:
            return SignalType.stdLogic.defaultValueCreation
        case .vector(let literal):
            switch literal {
            case .bits(let value):
                return "SignalLiteral.vector(value: .bits(value: BitVector(values: " +
                    "[BitLiteral](repeating: .low, count: \(value.count))))"
            case .logics(let value):
                return "SignalLiteral.vector(value: .logics(value: LogicVector(values: " +
                    "[LogicLiteral](repeating: .low, count: \(value.count))))"
            case .octal(let value):
                return "SignalLiteral.vector(value: .bits(value: BitVector(values: " +
                    "[BitLiteral](repeating: .low, count: \(value.values.count * 3))))"
            case .hexademical(let value):
                return "SignalLiteral.vector(value: .bits(value: BitVector(values: " +
                    "[BitLiteral](repeating: .low, count: \(value.values.count * 4))))"
            case .indexed:
                fatalError("Cannot create default value for indexed vector.")
            }
        }
    }

}
