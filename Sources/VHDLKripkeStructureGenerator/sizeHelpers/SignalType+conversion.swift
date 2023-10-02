// SignalType+conversion.swift
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

extension SignalType {

    @inlinable
    func conversion(value: Expression) -> Expression {
        switch self {
        case .bit, .stdULogic:
            return .cast(operation: .stdLogic(expression: value))
        case .boolean:
            return .functionCall(call: .custom(function: CustomFunctionCall(
                name: .boolToStdLogic, parameters: [Argument(argument: value)]
            )))
        case .integer:
            return .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                function: CustomFunctionCall(
                    name: .toSigned,
                    parameters: [
                        Argument(argument: value),
                        Argument(argument: .literal(value: .integer(value: 32)))
                    ]
                )
            ))))
        case .natural, .positive:
            return .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                function: CustomFunctionCall(
                    name: .toUnsigned,
                    parameters: [
                        Argument(argument: value),
                        Argument(argument: .literal(value: .integer(value: 32)))
                    ]
                )
            ))))
        case .stdLogic:
            return value
        case .real:
            fatalError("Cannot cast real values")
        case .ranged(let type):
            return type.conversion(value: value)
        }
    }

    func conversion(value: Expression, to type: SignalType) -> Expression {
        guard case .ranged(let rangedType) = self else {
            guard self == .stdLogic else {
                fatalError("Unsupported conversion from \(self) to \(type)!")
            }
            switch type {
            case .bit:
                return .cast(operation: .bit(expression: value))
            case .boolean:
                return .functionCall(call: .custom(function: CustomFunctionCall(
                    name: .stdLogicToBool, parameters: [Argument(argument: value)]
                )))
            case .integer, .natural, .positive:
                fatalError("Trying to convert from std_logic to integer!")
            case .stdLogic:
                return value
            case .stdULogic:
                return .cast(operation: .stdULogic(expression: value))
            case .real:
                fatalError("Cannot cast real values")
            case .ranged:
                fatalError("Impossible to get here!")
            }
        }
        return rangedType.conversion(value: value, to: type)
    }

}

extension RangedType {

    @inlinable
    func conversion(value: Expression) -> Expression {
        switch self {
        case .bitVector, .stdULogicVector, .signed, .unsigned:
            return .cast(operation: .stdLogicVector(expression: value))
        case .integer(let size):
            guard case .literal(let literal) = size.min, case .integer(let min) = literal, min < 0 else {
                return .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                    function: CustomFunctionCall(
                        name: .toSigned,
                        parameters: [
                            Argument(argument: value),
                            Argument(argument: .literal(value: .integer(value: self.bits)))
                        ]
                    )
                ))))
            }
            return .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                function: CustomFunctionCall(
                    name: .toUnsigned,
                    parameters: [
                        Argument(argument: value),
                        Argument(argument: .literal(value: .integer(value: self.bits)))
                    ]
                )
            ))))
        case .stdLogicVector:
            return value
        }
    }

    func conversion(value: Expression, to type: SignalType) -> Expression {
        guard case .stdLogicVector = self else {
            fatalError("Unsupported conversion from \(self) to \(type)!")
        }
        switch type {
        case .integer:
            return .functionCall(call: .custom(function: CustomFunctionCall(
                name: .toInteger,
                parameters: [Argument(argument: .cast(operation: .signed(expression: value)))]
            )))
        case .natural, .positive:
            return .functionCall(call: .custom(function: CustomFunctionCall(
                name: .toInteger,
                parameters: [Argument(argument: .cast(operation: .unsigned(expression: value)))]
            )))
        case .ranged(let rangedType):
            switch rangedType {
            case .bitVector:
                return .cast(operation: .bitVector(expression: value))
            case .integer(let size):
                guard
                    case .literal(let literal) = size.min,
                    case .integer(let min) = literal,
                    min >= 0
                else {
                    return .functionCall(call: .custom(function: CustomFunctionCall(
                        name: .toInteger,
                        parameters: [Argument(argument: .cast(operation: .signed(expression: value)))]
                    )))
                }
                return .functionCall(call: .custom(function: CustomFunctionCall(
                    name: .toInteger,
                    parameters: [Argument(argument: .cast(operation: .unsigned(expression: value)))]
                )))
            case .signed:
                return .cast(operation: .signed(expression: value))
            case .stdLogicVector:
                return value
            case .stdULogicVector:
                return .cast(operation: .stdULogicVector(expression: value))
            case .unsigned:
                return .cast(operation: .unsigned(expression: value))
            }
        case .bit, .boolean, .real, .stdLogic, .stdULogic:
            fatalError("Unsupported conversion from \(self) to \(type)!")
        }
    }

}
