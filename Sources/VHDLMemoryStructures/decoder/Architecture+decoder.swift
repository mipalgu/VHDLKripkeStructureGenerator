// Architecture+decoder.swift
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

/// Add decoder creation.
extension Architecture {

    /// The architecture for a generic decoder.
    @inlinable
    init?(decoderName name: VariableName, numberOfElements: Int, elementSize: Int) {
        guard numberOfElements > 0, elementSize > 0 else {
            return nil
        }
        guard (elementSize + 1) * numberOfElements <= 32 else {
            self.init(largeDecoderName: name, numberOfElements: numberOfElements, elementSize: elementSize)
            return
        }
        let statements = (0..<numberOfElements).flatMap {
            let topIndex = 32 - $0 * (elementSize + 1) - 1
            let bottomIndex = topIndex - elementSize + 1
            return [
                AsynchronousBlock.statement(statement: .assignment(
                    // swiftlint:disable:next force_unwrapping
                    name: .variable(reference: .variable(name: VariableName(rawValue: "out\($0)")!)),
                    value: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .data))),
                        index: .range(value: .downto(
                            upper: .literal(value: .integer(value: topIndex)),
                            lower: .literal(value: .integer(value: bottomIndex))
                        ))
                    )))
                )),
                AsynchronousBlock.statement(statement: .assignment(
                    // swiftlint:disable:next force_unwrapping
                    name: .variable(reference: .variable(name: VariableName(rawValue: "out\($0)en")!)),
                    value: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .data))),
                        index: .index(value: .literal(value: .integer(value: bottomIndex - 1)))
                    )))
                ))
            ]
        }
        let body = AsynchronousBlock.blocks(blocks: statements)
        self.init(body: body, entity: name, head: ArchitectureHead(statements: []), name: .behavioral)
    }

    @inlinable
    init?(largeDecoderName name: VariableName, numberOfElements: Int, elementSize: Int) {
        guard numberOfElements == 1, elementSize > 31 else {
            return nil
        }
        let numberOfAddresses = Int((Double(elementSize) / 31.0).rounded(.up))
        let paddingAmount = numberOfAddresses * 31 - elementSize
        let ranges = (0..<numberOfAddresses).map {
            let size: VectorSize
            if $0 == numberOfAddresses - 1, paddingAmount != 0 {
                size = VectorSize.downto(
                    upper: .literal(value: .integer(value: 31)),
                    lower: .literal(value: .integer(value: paddingAmount + 1))
                )
            } else {
                size = VectorSize.downto(
                    upper: .literal(value: .integer(value: 31)),
                    lower: .literal(value: .integer(value: 1))
                )
            }
            return Expression.reference(variable: .indexed(
                name: .reference(variable: .variable(
                    reference: .variable(name: VariableName(rawValue: "data\($0)")!)
                )),
                index: .range(value: size)
            ))
        }
        let conditionals = (0..<numberOfAddresses).map {
            let index = Expression.reference(variable: .indexed(
                name: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "data\($0)")!
                ))),
                index: .index(value: .literal(value: .integer(value: 0)))
            ))
            return Expression.conditional(condition: .comparison(value: .equality(
                lhs: index,
                rhs: .literal(value: .bit(value: .high))
            )))
        }
        let expression = ranges.joined { Expression.binary(operation: .concatenate(lhs: $0, rhs: $1)) }
        let enable = conditionals.joined { Expression.logical(operation: .and(lhs: $0, rhs: $1)) }
        let statements: [AsynchronousBlock] = [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: VariableName(rawValue: "out0")!)),
                value: .expression(value: expression)
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: VariableName(rawValue: "out0en")!)),
                value: .expression(value: .functionCall(call: .custom(function: CustomFunctionCall(
                    name: .boolToStdLogic,
                    parameters: [Argument(argument: enable)]
                ))))
            ))
        ]
        self.init(
            body: .blocks(blocks: statements),
            entity: name,
            head: ArchitectureHead(statements: []),
            name: .behavioral
        )
    }

}
