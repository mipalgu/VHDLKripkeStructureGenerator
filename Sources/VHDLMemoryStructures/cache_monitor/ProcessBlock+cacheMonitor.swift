// ProcessBlock+cacheMonitor.swift
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

extension ProcessBlock {

    init?(cacheMonitorNumberOfMembers members: Int) {
        guard members > 0 else {
            return nil
        }
        let firstMember = [BitLiteral](repeating: .low, count: members - 1) + [.high]
        let lastMembers = [.high] + [BitLiteral](repeating: .low, count: members - 1)
        let shiftExpression: Expression
        if members == 1 {
            shiftExpression = .literal(value: .vector(value: .bits(value: BitVector(values: [.high]))))
        } else {
            shiftExpression = .binary(operation: .concatenate(
                lhs: .reference(variable: .indexed(
                    name: .reference(variable: .variable(
                        reference: .variable(name: .enables)
                    )),
                    index: .range(value: .downto(
                        upper: .literal(value: .integer(value: members - 2)),
                        lower: .literal(value: .integer(value: 0))
                    ))
                )),
                rhs: .literal(value: .vector(value: .bits(
                    value: BitVector(values: [.low])
                )))
            ))
        }
        let body = SynchronousBlock.ifStatement(block: .ifStatement(
            condition: .conditional(condition: .edge(value: .rising(expression: .reference(
                variable: .variable(reference: .variable(name: .clk))
            )))),
            ifBlock: .caseStatement(block: CaseStatement(
                condition: .reference(variable: .variable(reference: .variable(name: .internalState))),
                cases: [
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .initial))
                        )),
                        code: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .enables)),
                                value: .literal(value: .vector(value: .bits(
                                    value: BitVector(values: firstMember)
                                )))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(
                                    variable: .variable(reference: .variable(name: .waitForAccess))
                                )
                            ))
                        ])
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(variable: .variable(
                            reference: .variable(name: .waitWhileBusy)
                        ))),
                        code: .ifStatement(block: .ifStatement(
                            condition: .conditional(condition: .comparison(value: .notEquals(
                                lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                                rhs: .literal(value: .bit(value: .high))
                            ))),
                            ifBlock: .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(
                                    variable: .variable(reference: .variable(name: .chooseAccess))
                                )
                            ))
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(variable: .variable(
                            reference: .variable(name: .chooseAccess)
                        ))),
                        code: .blocks(blocks: [
                            .ifStatement(block: .ifElse(
                                condition: .conditional(condition: .comparison(value: .equality(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .enables)
                                    )),
                                    rhs: .literal(value: .vector(value: .bits(
                                        value: BitVector(values: lastMembers)
                                    )))
                                ))),
                                ifBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .enables)),
                                    value: .literal(value: .vector(value: .bits(
                                        value: BitVector(values: firstMember)
                                    )))
                                )),
                                elseBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .enables)),
                                    value: shiftExpression
                                ))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(
                                    variable: .variable(reference: .variable(name: .waitForAccess))
                                )
                            ))
                        ])
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(variable: .variable(
                            reference: .variable(name: .waitForAccess)
                        ))),
                        code: .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(
                                variable: .variable(reference: .variable(name: .waitWhileBusy))
                            )
                        ))
                    )
                ]
            ))
        ))
        self.init(sensitivityList: [.clk], code: body)
    }

}
