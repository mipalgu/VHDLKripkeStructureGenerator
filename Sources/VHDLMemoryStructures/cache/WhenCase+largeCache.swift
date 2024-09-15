// WhenCase+largeCache.swift
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

/// Add large cache cases.
extension WhenCase {

    /// The `Initial` case for a large cache.
    @usableFromInline static let largeCacheInitial = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .initial)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .writeValue)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .writeEnable)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentValues)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(
                            index: .others,
                            value: .literal(value: .vector(value: .indexed(
                                values: IndexedVector(
                                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                                )
                            )))
                        )
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentAddress)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForNewDataType)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .maxAddress)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            ))
        ])
    )

    /// The `ReadElement` case for a large cache.
    @usableFromInline static let largeCacheReadElement = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .readElement)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .setReadAddress)))
            )),
            .statement(statement: .assignment(
                name: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .currentValues))),
                    index: .index(
                        value: .reference(variable: .variable(reference: .variable(name: .memoryIndex)))
                    )
                ),
                value: .reference(variable: .variable(reference: .variable(name: .valueBRAM)))
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

    /// The `WaitForNewData` case for a large cache.
    @usableFromInline static let largeCacheWaitForNewData = WhenCase(
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
                        name: .variable(reference: .variable(name: .currentAddress)),
                        value: .cast(operation: .stdLogicVector(
                            expression: .binary(operation: .multiplication(
                                lhs: .reference(
                                    variable: .variable(reference: .variable(name: .unsignedAddress))
                                ),
                                rhs: .literal(value: .integer(value: 2))
                            ))
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .writeValue)),
                        value: .reference(variable: .variable(reference: .variable(name: .data)))
                    )),
                    .ifStatement(block: .ifStatement(
                        condition: .conditional(condition: .comparison(value: .lessThan(
                            lhs: .reference(variable: .variable(reference: .variable(name: .maxAddress))),
                            rhs: .reference(variable: .variable(reference: .variable(name: .unsignedAddress)))
                        ))),
                        ifBlock: .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .maxAddress)),
                            value: .reference(
                                variable: .variable(reference: .variable(name: .unsignedAddress))
                            )
                        ))
                    ))
                ]),
                elseBlock: .ifStatement(block: .ifElse(
                    condition: .logical(operation: .and(
                        lhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                            rhs: .literal(value: .bit(value: .high))
                        ))),
                        rhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .we))),
                            rhs: .literal(value: .bit(value: .low))
                        )))
                    )),
                    ifBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(reference: .variable(name: .readElement)))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .busy)),
                            value: .literal(value: .bit(value: .high))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .currentAddress)),
                            value: .cast(operation: .stdLogicVector(
                                expression: .binary(operation: .multiplication(
                                    lhs: .reference(
                                        variable: .variable(reference: .variable(name: .unsignedAddress))
                                    ),
                                    rhs: .literal(value: .integer(value: 2))
                                ))
                            ))
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
                        ))
                    ])
                ))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            ))
        ])
    )

    /// The `WaitOneCycle` case for a large cache.
    @usableFromInline static let largeCacheWaitOneCycle = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .waitOneCycle)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .weBRAM)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForNewDataType)))
            ))
        ])
    )

    // swiftlint:disable function_body_length

    /// The `SetReadAddress` case for a large cache.
    /// - Parameter size: The size of a single element in the cache.
    @inlinable
    init(largeCacheSetReadAddressWithElementSize size: Int) {
        let addressesPerElement = Int((Double(size) / 31.0).rounded(.up))
        self.init(
            condition: .expression(
                expression: .reference(variable: .variable(reference: .variable(name: .setReadAddress)))
            ),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                        rhs: .literal(value: .integer(value: addressesPerElement - 1))
                    ))),
                    ifBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(reference: .variable(name: .waitOneCycle)))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .busy)),
                            value: .literal(value: .bit(value: .low))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .valueEn)),
                            value: .reference(variable: .variable(reference: .variable(name: .readEnable)))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .value)),
                            value: .reference(variable: .variable(reference: .variable(name: .readValue)))
                        ))
                    ]),
                    elseBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .memoryIndex)),
                            value: .binary(operation: .addition(
                                lhs: .reference(
                                    variable: .variable(reference: .variable(name: .memoryIndex))
                                ),
                                rhs: .literal(value: .integer(value: 1))
                            ))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(reference: .variable(name: .readElement)))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .busy)),
                            value: .literal(value: .bit(value: .high))
                        ))
                    ])
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .weBRAM)),
                    value: .literal(value: .bit(value: .low))
                ))
            ])
        )
    }

    /// The `WriteElement` case for a large cache.
    /// - Parameter size: The size of a single element in the cache.
    @inlinable
    init(largeCacheWriteElementWithElementSize size: Int) {
        let addressesPerElement = Int((Double(size) / 31.0).rounded(.up))
        self.init(
            condition: .expression(
                expression: .reference(variable: .variable(reference: .variable(name: .writeElement)))
            ),
            code: .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                    rhs: .literal(value: .integer(value: addressesPerElement - 1))
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .internalState)),
                        value: .reference(variable: .variable(reference: .variable(name: .waitOneCycle)))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .weBRAM)),
                        value: .literal(value: .bit(value: .low))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .low))
                    ))
                ]),
                elseBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .memoryIndex)),
                        value: .binary(operation: .addition(
                            lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                            rhs: .literal(value: .integer(value: 1))
                        ))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .weBRAM)),
                        value: .literal(value: .bit(value: .high))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .high))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .di)),
                        value: .reference(variable: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .values))),
                            index: .index(value: .reference(
                                variable: .variable(reference: .variable(name: .memoryIndex))
                            ))
                        ))
                    ))
                ])
            ))
        )
    }

    // swiftlint:enable function_body_length

}
