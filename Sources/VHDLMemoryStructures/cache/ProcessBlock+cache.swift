// ProcessBlock+cache.swift
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

/// Add cache creation.
extension ProcessBlock {

    /// Generate a cache.
    @inlinable
    init?(cacheName name: VariableName, elementSize size: Int, numberOfElements: Int) {
        guard size > 0, numberOfElements > 0 else {
            return nil
        }
        guard size <= 31 else {
            fatalError("Currently cannot support element sizes greater than 31 bits")
        }
        guard
            let writeElement = WhenCase(cacheWriteElementSize: size, numberOfElements: numberOfElements)
        else {
            return nil
        }
        self.init(
            sensitivityList: [.clk],
            code: .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .edge(value: .rising(
                    expression: .reference(variable: .variable(reference: .variable(name: .clk)))
                ))),
                ifBlock: .caseStatement(block: CaseStatement(
                    condition: .reference(variable: .variable(reference: .variable(name: .internalState))),
                    cases: [
                        .cacheInitial, .cacheWaitForNewData, writeElement, .cacheIncrementIndex,
                        .cacheResetEnables, .cacheOthers
                    ]
                ))
            ))
        )
    }

}

/// Add cache process cases.
extension WhenCase {

    /// The `IncrementIndex` case in the cache process.
    @usableFromInline static let cacheIncrementIndex = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .incrementIndex)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .cacheIndex)),
                value: .binary(operation: .addition(
                    lhs: .reference(variable: .variable(reference: .variable(name: .cacheIndex))),
                    rhs: .literal(value: .integer(value: 1))
                ))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForNewDataType)))
            ))
        ])
    )

    /// The `Initial` case in the cache process.
    @usableFromInline static let cacheInitial = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .initial)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .cache)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(
                            index: .others,
                            value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                                values: [
                                    IndexedValue(index: .others, value: .bit(value: .low))
                                ]
                            ))))
                        )
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .enables)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(index: .others, value: .bit(value: .low))
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .cacheIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .lastAddress)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(index: .others, value: .bit(value: .low))
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForNewDataType)))
            ))
        ])
    )

    /// The `others` case in the cache process.
    @usableFromInline static let cacheOthers = WhenCase(
        condition: .others,
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .error)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            ))
        ])
    )

    /// The `ResetEnables` case in the cache process.
    @usableFromInline static let cacheResetEnables = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .resetEnables)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .cacheIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .cache)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(
                            index: .others,
                            value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                                values: [
                                    IndexedValue(index: .others, value: .bit(value: .low))
                                ]
                            ))))
                        )
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .enables)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(index: .others, value: .bit(value: .low))
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryIndex)),
                value: .binary(operation: .addition(
                    lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                    rhs: .literal(value: .integer(value: 1))
                ))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForNewDataType)))
            ))
        ])
    )

    /// The `WaitForNewData` case in the cache process.
    @usableFromInline static let cacheWaitForNewData = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .waitForNewDataType)))
        ),
        code: .blocks(blocks: [
            .ifStatement(block: .ifElse(
                condition: .logical(operation: .and(
                    lhs: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                        rhs: .literal(value: .bit(value: .high))
                    ))),
                    rhs: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .we))),
                        rhs: .literal(value: .bit(value: .high))
                    )))
                )),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .internalState)),
                        value: .reference(variable: .variable(reference: .variable(name: .writeElement)))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .high))
                    )),
                    .statement(statement: .assignment(
                        name: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .cache))),
                            index: .index(value: .reference(
                                variable: .variable(reference: .variable(name: .cacheIndex))
                            ))
                        ),
                        value: .reference(variable: .variable(reference: .variable(name: .data)))
                    )),
                    .statement(statement: .assignment(
                        name: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .enables))),
                            index: .index(value: .reference(
                                variable: .variable(reference: .variable(name: .cacheIndex))
                            ))
                        ),
                        value: .literal(value: .bit(value: .high))
                    ))
                ]),
                elseBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .internalState)),
                        value: .reference(
                            variable: .variable(reference: .variable(name: .waitForNewDataType))
                        )
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .low))
                    )),
                    .statement(statement: .assignment(
                        name: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .cache))),
                            index: .index(value: .reference(
                                variable: .variable(reference: .variable(name: .cacheIndex))
                            ))
                        ),
                        value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                            values: [
                                IndexedValue(index: .others, value: .bit(value: .low))
                            ]
                        ))))
                    )),
                    .statement(statement: .assignment(
                        name: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .enables))),
                            index: .index(value: .reference(
                                variable: .variable(reference: .variable(name: .cacheIndex))
                            ))
                        ),
                        value: .literal(value: .bit(value: .low))
                    ))
                ])
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            ))
        ])
    )

    // swiftlint:disable function_body_length

    /// The `WriteElement` case in the cache process.
    @inlinable
    init?(cacheWriteElementSize size: Int, numberOfElements: Int) {
        guard size > 0, numberOfElements > 0 else {
            return nil
        }
        guard size <= 31 else {
            fatalError("Currently cannot support element sizes greater than 31 bits")
        }
        let encodedSize = size + 1
        let elementsPerAddress = 31 / encodedSize
        let numberOfAddresses = numberOfElements.isMultiple(of: elementsPerAddress)
            ? numberOfElements / elementsPerAddress : numberOfElements / elementsPerAddress + 1
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .writeElement)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                        rhs: .literal(value: .integer(value: numberOfAddresses))
                    ))),
                    ifBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(reference: .variable(name: .error)))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .weBRAM)),
                            value: .literal(value: .bit(value: .low))
                        ))
                    ]),
                    elseBlock: .ifStatement(block: .ifElse(
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .cacheIndex))),
                            rhs: .literal(value: .integer(value: elementsPerAddress - 1))
                        ))),
                        ifBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .weBRAM)),
                                value: .literal(value: .bit(value: .high))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(
                                    variable: .variable(reference: .variable(name: .resetEnables))
                                )
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .lastAddress)),
                                value: .reference(variable: .variable(reference: .variable(name: .genIndex)))
                            ))
                        ]),
                        elseBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .weBRAM)),
                                value: .literal(value: .bit(value: .high))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(
                                    variable: .variable(reference: .variable(name: .incrementIndex))
                                )
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .lastAddress)),
                                value: .reference(variable: .variable(reference: .variable(name: .genIndex)))
                            ))
                        ])
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .high))
                ))
            ])
        )
    }

    // swiftlint:enable function_body_length

}
