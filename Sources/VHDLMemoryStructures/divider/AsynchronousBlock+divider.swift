// AsynchronousBlock+divider.swift
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

/// Add divider creation.
extension AsynchronousBlock {

    /// The default logic for a division circuit. No divide is performed.
    @usableFromInline static let defaultDivide = AsynchronousBlock.blocks(blocks: [
        .statement(statement: .assignment(
            name: .variable(reference: .variable(name: .result)),
            value: .expression(value: .reference(variable: .variable(
                reference: .variable(name: .numerator)
            )))
        )),
        .statement(statement: .assignment(
            name: .variable(reference: .variable(name: .remainder)),
            value: .expression(value: .literal(value: .vector(value: .indexed(
                values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                )
            ))))
        ))
    ])

    /// The logic for a division circuit that divides by powers of 2 through shift registers.
    @usableFromInline static let divideLogic = AsynchronousBlock.blocks(blocks: [
        .statement(statement: .assignment(
            name: .variable(reference: .variable(name: .result)),
            value: .expression(value: .cast(operation: .stdLogicVector(
                expression: .functionCall(call: .custom(function: CustomFunctionCall(
                    name: .shiftRight,
                    parameters: [
                        Argument(argument: .cast(operation: .unsigned(expression: .reference(
                            variable: .variable(reference: .variable(name: .numerator))
                        )))),
                        Argument(argument: .reference(variable: .variable(
                            reference: .variable(name: .divisor)
                        )))
                    ]
                )))
            )))
        )),
        .statement(statement: .assignment(
            name: .variable(reference: .variable(name: .remainder)),
            value: .expression(value: .binary(operation: .concatenate(
                lhs: .reference(variable: .variable(reference: .variable(name: .zero))),
                rhs: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .numerator))),
                    index: .range(value: .downto(
                        upper: .binary(operation: .subtraction(
                            lhs: .reference(variable: .variable(reference: .variable(name: .divisor))),
                            rhs: .literal(value: .integer(value: 1))
                        )),
                        lower: .literal(value: .integer(value: 0))
                    ))
                ))
            )))
        ))
    ])

    /// Create the logic for a division circuit that uses powers of 2.
    /// - Parameter size: The size of the numerator to divide by.
    @inlinable
    init?(dividerSize size: Int) {
        guard size > 0, size <= 32 else {
            return nil
        }
        guard size <= 15 else {
            self = .defaultDivide
            return
        }
        self = .divideLogic
    }

}
