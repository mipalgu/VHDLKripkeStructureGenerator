// WhenCase+writeElement.swift
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

import Foundation
import VHDLMachines
import VHDLParsing

extension WhenCase {

    init<T>(
        ringletCacheSmallWriteElementFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let ringletsPerAddress = state.ringletsPerAddress(in: representation)
        let arrayMaxIndex = ringletsPerAddress - 1
        let ringletMax = state.encodedSize(in: representation) - 1
        let condition = [
            Expression.conditional(condition: .comparison(value: .equality(
                lhs: .reference(variable: .indexed(
                    name: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .workingRinglets))),
                        index: .index(value: .reference(variable: .variable(
                            reference: .variable(name: .ringletIndex)
                        )))
                    )),
                    index: .index(value: .literal(value: .integer(value: ringletMax)))
                )),
                rhs: .literal(value: .bit(value: .high))
            ))),
            .logical(operation: .not(value: .reference(variable: .variable(
                reference: .variable(name: .isDuplicate)
            ))))
        ]
        .joined { Expression.logical(operation: .and(lhs: $0, rhs: $1)) }
        let maxMemoryIndex = state.numberOfMemoryAddresses(for: state, in: representation)
        let machine = representation.machine
        let ringletAccess = (0..<(ringletsPerAddress - 1)).dropLast().map {
            Expression.reference(variable: .indexed(
                name: .reference(variable: .variable(reference: .variable(name: .currentRinglet))),
                index: .index(value: .literal(value: .integer(value: $0)))
            ))
        }
        let lastElement = Expression.reference(variable: .indexed(
            name: .reference(variable: .variable(reference: .variable(name: .workingRinglets))),
            index: .index(value: .reference(variable: .variable(reference: .variable(name: .ringletIndex))))
        ))
        let stateBits = machine.numberOfStateBits
        let remainingBits = 32 - stateBits - state.encodedSize(in: representation)
        guard remainingBits >= 0, let stateEncoding = machine.states.firstIndex(where: { $0 == state }) else {
            fatalError("Incorrect number of remaining bits \(remainingBits) for this ringlet cache.")
        }
        let bitString = BitLiteral.bitVersion(of: stateEncoding, bitsRequired: stateBits)
        let workingCache = (ringletAccess + [lastElement] + [
            Expression.literal(value: .vector(value: .bits(
                value: BitVector(values: [BitLiteral](repeating: .low, count: remainingBits))
            ))),
            .literal(value: .vector(value: .bits(value: BitVector(values: bitString))))
        ]).concatenated
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .writeElement)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(
                            reference: .variable(name: .currentRingletIndex)
                        )),
                        rhs: .literal(value: .integer(value: arrayMaxIndex))
                    ))),
                    ifBlock: .ifStatement(block: .ifElse(
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                            rhs: .literal(value: .integer(value: maxMemoryIndex))
                        ))),
                        ifBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(variable: .variable(reference: .variable(name: .error)))
                            ))
                        ]),
                        elseBlock: .blocks(blocks: [
                            .ifStatement(block: .ifElse(
                                condition: condition,
                                ifBlock: .blocks(blocks: [
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .di)),
                                        value: workingCache
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .memoryIndex)),
                                        value: .binary(operation: .addition(
                                            lhs: .reference(variable: .variable(
                                                reference: .variable(name: .memoryIndex)
                                            )),
                                            rhs: .literal(value: .integer(value: 1))
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .genIndex)),
                                        value: .cast(operation: .stdLogicVector(
                                            expression: .functionCall(call: .custom(
                                                function: CustomFunctionCall(
                                                    name: .toUnsigned,
                                                    parameters: [
                                                        Argument(argument: .reference(variable: .variable(
                                                            reference: .variable(name: .memoryIndex)
                                                        ))),
                                                        Argument(
                                                            argument: .literal(value: .integer(value: 32))
                                                        )
                                                    ]
                                                )
                                            ))
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .we)),
                                        value: .literal(value: .bit(value: .high))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .currentRinglet)),
                                        value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                                            values: [
                                                IndexedValue(
                                                    index: .others,
                                                    value: .literal(value: .vector(value: .indexed(
                                                        values: IndexedVector(values: [
                                                            IndexedValue(
                                                                index: .others, value: .bit(value: .low)
                                                            )
                                                        ])
                                                    )))
                                                )
                                            ]
                                        ))))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .currentRingletIndex)),
                                        value: .literal(value: .integer(value: 0))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .currentRingletAddress)),
                                        value: .cast(operation: .stdLogicVector(expression: .binary(
                                            operation: .addition(
                                                lhs: .cast(operation: .unsigned(
                                                    expression: .reference(variable: .variable(
                                                        reference: .variable(name: .currentRingletAddress)
                                                    ))
                                                )),
                                                rhs: .literal(value: .integer(value: 1))
                                            )
                                        )))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .internalState)),
                                        value: .reference(variable: .variable(
                                            reference: .variable(name: .setRingletRAMValue)
                                        ))
                                    ))
                                ]),
                                elseBlock: .blocks(blocks: [
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .we)),
                                        value: .literal(value: .bit(value: .low))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .internalState)),
                                        value: .reference(variable: .variable(
                                            reference: .variable(name: .setRingletValue)
                                        ))
                                    ))
                                ])
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .isDuplicate)),
                                value: .literal(value: .boolean(value: false))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .ringletIndex)),
                                value: .binary(operation: .addition(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .ringletIndex)
                                    )),
                                    rhs: .literal(value: .integer(value: 1))
                                ))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .lastAddress)),
                                value: .reference(variable: .variable(
                                    reference: .variable(name: .currentRingletAddress)
                                ))
                            ))
                        ])
                    )),
                    elseBlock: .blocks(blocks: [
                        .ifStatement(block: .ifStatement(
                            condition: condition,
                            ifBlock: .blocks(blocks: [
                                .statement(statement: .assignment(
                                    name: .indexed(
                                        name: .reference(variable: .variable(
                                            reference: .variable(name: .currentRinglet)
                                        )),
                                        index: .index(value: .reference(variable: .variable(
                                            reference: .variable(name: .currentRingletIndex)
                                        )))
                                    ),
                                    value: .reference(variable: .indexed(
                                        name: .reference(variable: .variable(
                                            reference: .variable(name: .workingRinglets)
                                        )),
                                        index: .index(value: .reference(variable: .variable(
                                            reference: .variable(name: .ringletIndex)
                                        )))
                                    ))
                                )),
                                .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .currentRingletIndex)),
                                    value: .binary(operation: .addition(
                                        lhs: .reference(variable: .variable(
                                            reference: .variable(name: .currentRingletIndex)
                                        )),
                                        rhs: .literal(value: .integer(value: 1))
                                    ))
                                ))
                            ])
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .isDuplicate)),
                            value: .literal(value: .boolean(value: false))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .ringletIndex)),
                            value: .binary(operation: .addition(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .ringletIndex)
                                )),
                                rhs: .literal(value: .integer(value: 1))
                            ))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(
                                reference: .variable(name: .setRingletValue)
                            ))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .lastAddress)),
                            value: .reference(variable: .variable(
                                reference: .variable(name: .currentRingletAddress)
                            ))
                        ))
                    ])
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .high))
                ))
            ])
        )
    }

    init<T>(
        ringletCacheLargeWriteElementFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let memoryMaxIndex = max(0, state.numberOfMemoryAddresses(for: state, in: representation) - 1)
        let encodedSize = state.encodedSize(in: representation)
        let ringletLastIndex = max(0, encodedSize - 1)
        let numberOfAddresses = Int(ceil(Double(encodedSize) / 32.0))
        let stateSize = representation.machine.numberOfStateBits
        let nullBits = 32 * numberOfAddresses - encodedSize - stateSize
        guard nullBits < 32 && nullBits >= 0 else {
            fatalError(
                "Null bits calculation incorrect. Got \(nullBits) bits with \(numberOfAddresses) " +
                "addresses, \(encodedSize) encoded size, and \(stateSize) stateSize."
            )
        }
        let nullBitsEncoded = BitVector(values: [BitLiteral](repeating: .low, count: nullBits))
        let stateEncoding = state.representation(in: representation)
        let delimiter = Expression.binary(operation: .concatenate(
            lhs: .literal(value: .vector(value: .bits(value: nullBitsEncoded))),
            rhs: .literal(value: stateEncoding)
        ))
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .writeElement)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .memoryIndex))),
                        rhs: .literal(value: .integer(value: memoryMaxIndex))
                    ))),
                    ifBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(reference: .variable(name: .error)))
                        ))
                    ]),
                    elseBlock: .ifStatement(block: .ifElse(
                        condition: .logical(operation: .and(
                            lhs: .conditional(condition: .comparison(value: .equality(
                                lhs: .reference(variable: .indexed(
                                    name: .reference(variable: .indexed(
                                        name: .reference(variable: .variable(
                                            reference: .variable(name: .workingRinglets)
                                        )),
                                        index: .index(value: .reference(variable: .variable(
                                            reference: .variable(name: .ringletIndex)
                                        )))
                                    )),
                                    index: .index(value: .literal(value: .integer(value: ringletLastIndex)))
                                )),
                                rhs: .literal(value: .bit(value: .high))
                            ))),
                            rhs: .logical(operation: .not(value: .reference(variable: .variable(
                                reference: .variable(name: .isDuplicate)
                            ))))
                        )),
                        ifBlock: .blocks(blocks: [
                            .ifStatement(block: .ifElse(
                                condition: .conditional(condition: .comparison(value: .greaterThan(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .topIndex)
                                    )),
                                    rhs: .literal(value: .integer(value: 31))
                                ))),
                                ifBlock: .blocks(blocks: [
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .di)),
                                        value: .reference(variable: .indexed(
                                            name: .reference(variable: .indexed(
                                                name: .reference(variable: .variable(
                                                    reference: .variable(name: .workingRinglets)
                                                )),
                                                index: .index(value: .reference(variable: .variable(
                                                    reference: .variable(name: .ringletIndex)
                                                )))
                                            )),
                                            index: .range(value: .downto(
                                                upper: .reference(variable: .variable(
                                                    reference: .variable(name: .topIndex)
                                                )),
                                                lower: .binary(operation: .subtraction(
                                                    lhs: .reference(variable: .variable(
                                                        reference: .variable(name: .topIndex)
                                                    )),
                                                    rhs: .literal(value: .integer(value: 31))
                                                ))
                                            ))
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .topIndex)),
                                        value: .binary(operation: .subtraction(
                                            lhs: .reference(variable: .variable(
                                                reference: .variable(name: .topIndex)
                                            )),
                                            rhs: .literal(value: .integer(value: 32))
                                        ))
                                    ))
                                ]),
                                elseBlock: .blocks(blocks: [
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .di)),
                                        value: .binary(operation: .concatenate(
                                            lhs: .reference(variable: .indexed(
                                                name: .reference(variable: .indexed(
                                                    name: .reference(variable: .variable(
                                                        reference: .variable(name: .workingRinglets)
                                                    )),
                                                    index: .index(value: .reference(variable: .variable(
                                                        reference: .variable(name: .ringletIndex)
                                                    )))
                                                )),
                                                index: .range(value: .downto(
                                                    upper: .reference(variable: .variable(
                                                        reference: .variable(name: .topIndex)
                                                    )),
                                                    lower: .literal(value: .integer(value: 0))
                                                ))
                                            )),
                                            rhs: delimiter
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .ringletIndex)),
                                        value: .binary(operation: .addition(
                                            lhs: .reference(variable: .variable(
                                                reference: .variable(name: .ringletIndex)
                                            )),
                                            rhs: .literal(value: .integer(value: 1))
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .internalState)),
                                        value: .reference(variable: .variable(
                                            reference: .variable(name: .checkPreviousRinglets)
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .topIndex)),
                                        value: .literal(value: .integer(value: ringletLastIndex))
                                    ))
                                ])
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .memoryIndex)),
                                value: .binary(operation: .addition(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .memoryIndex)
                                    )),
                                    rhs: .literal(value: .integer(value: 1))
                                ))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .genIndex)),
                                value: .cast(operation: .stdLogicVector(expression: .functionCall(
                                    call: .custom(function: CustomFunctionCall(
                                        name: .toUnsigned,
                                        parameters: [
                                            Argument(argument: .reference(variable: .variable(
                                                reference: .variable(name: .memoryIndex)
                                            ))),
                                            Argument(argument: .literal(value: .integer(value: 32)))
                                        ]
                                    ))
                                )))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .we)),
                                value: .literal(value: .bit(value: .high))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .lastAddress)),
                                value: .cast(operation: .stdLogicVector(expression: .functionCall(
                                    call: .custom(function: CustomFunctionCall(
                                        name: .toUnsigned,
                                        parameters: [
                                            Argument(argument: .reference(variable: .variable(
                                                reference: .variable(name: .memoryIndex)
                                            ))),
                                            Argument(argument: .literal(value: .integer(value: 32)))
                                        ]
                                    ))
                                )))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .isDuplicate)),
                                value: .literal(value: .boolean(value: false))
                            ))
                        ]),
                        elseBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .we)),
                                value: .literal(value: .bit(value: .low))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(variable: .variable(
                                    reference: .variable(name: .checkPreviousRinglets)
                                ))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .isDuplicate)),
                                value: .literal(value: .boolean(value: false))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .ringletIndex)),
                                value: .binary(operation: .addition(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .ringletIndex)
                                    )),
                                    rhs: .literal(value: .integer(value: 1))
                                ))
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

}
