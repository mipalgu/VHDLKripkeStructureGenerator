// WhenCase+uartTransmitter.swift
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

extension WhenCase {

    static let initial = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(
            reference: .variable(name: .initial)
        ))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .tx)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .bitCount)),
                value: .literal(value: .integer(value: 7))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentState)),
                value: .reference(variable: .variable(
                    reference: .variable(name: .waitForReady)
                ))
            ))
        ])
    )

    static let waitForReady = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(
            reference: .variable(name: .waitForReady)
        ))),
        code: .ifStatement(block: .ifElse(
            condition: .conditional(condition: .comparison(value: .equality(
                lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                rhs: .literal(value: .bit(value: .high))
            ))),
            ifBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .data)),
                    value: .reference(variable: .variable(
                        reference: .variable(name: .word)
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .tx)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(
                        reference: .variable(name: .waitForStopLow)
                    ))
                ))
            ]),
            elseBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .tx)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .low))
                ))
            ])
        ))
    )

    static let waitForStopLow = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .waitForStopLow
        )))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .tx)),
                value: .literal(value: .bit(value: .high))
            )),
            .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .low))
                ))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(
                        reference: .variable(name: .waitForStopPulse)
                    ))
                ))
            ))
        ])
    )

    static let waitForStopPulse = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .waitForStopPulse
        )))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .tx)),
                        value: .literal(value: .bit(value: .low))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .currentState)),
                        value: .reference(variable: .variable(
                            reference: .variable(name: .waitForDataLow)
                        ))
                    ))
                ]),
                elseBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .tx)),
                    value: .literal(value: .bit(value: .high))
                ))
            ))
        ])
    )

    static let waitForDataLow = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .waitForDataLow
        )))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .tx)),
                value: .literal(value: .bit(value: .low))
            )),
            .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .low))
                ))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(
                        reference: .variable(name: .waitForDataHigh)
                    ))
                ))
            ))
        ])
    )

    static let waitForDataHigh = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .waitForDataHigh
        )))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .tx)),
                        value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .data))),
                            index: .index(value: .literal(value: .integer(value: 7)))
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .currentState)),
                        value: .reference(variable: .variable(
                            reference: .variable(name: .sentDataBit)
                        ))
                    ))
                ]),
                elseBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .tx)),
                    value: .literal(value: .bit(value: .low))
                ))
            ))
        ])
    )

    static let sentDataBit = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .sentDataBit
        )))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .tx)),
                value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .data))),
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .bitCount)
                    )))
                ))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .low))
                ))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(
                        reference: .variable(name: .waitForBitPulse)
                    ))
                ))
            ))
        ])
    )

    static let waitForBitPulse = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .waitForBitPulse
        )))),
        code: .ifStatement(block: .ifElse(
            condition: .logical(operation: .and(
                lhs: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                rhs: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .bitCount))),
                    rhs: .literal(value: .integer(value: 0))
                )))
            )),
            ifBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(
                        reference: .variable(name: .waitForReady)
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .tx)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .bitCount)),
                    value: .literal(value: .integer(value: 7))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .low))
                ))
            ]),
            elseBlock: .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .baudPulse))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .currentState)),
                        value: .reference(variable: .variable(
                            reference: .variable(name: .sentDataBit)
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .tx)),
                        value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .data))),
                            index: .index(value: .binary(operation: .subtraction(
                                lhs: .reference(variable: .variable(reference: .variable(name: .bitCount))),
                                rhs: .literal(value: .integer(value: 1))
                            )))
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .bitCount)),
                        value: .binary(operation: .subtraction(
                            lhs: .reference(variable: .variable(reference: .variable(name: .bitCount))),
                            rhs: .literal(value: .integer(value: 1))
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .high))
                    ))
                ]),
                elseBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .tx)),
                        value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .data))),
                            index: .index(value: .reference(variable: .variable(reference: .variable(
                                name: .bitCount
                            ))))
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .high))
                    ))
                ])
            ))
        ))
    )

}
