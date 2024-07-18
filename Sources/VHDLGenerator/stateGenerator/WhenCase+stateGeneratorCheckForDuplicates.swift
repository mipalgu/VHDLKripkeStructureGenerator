// WhenCase+stateGeneratorCheckForDuplicates.swift
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

import Utilities
import VHDLMachines
import VHDLParsing

extension WhenCase {

    init?<T>(
        sequentialStateGeneratorCheckForDuplicatesFor state: State,
        in representation: T,
        maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let maxIndex = machine.numberOfTargetStates
        let observedIndex = state.encodedSize(in: representation) - 1
        guard let executionMaxIndex = state.executionSize(
            in: representation, maxExecutionSize: maxExecutionSize
        ).size else {
            return nil
        }
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let readBits = readSnapshot.encodedBits
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let ifStatement = SynchronousBlock.ifStatement(block: .ifStatement(
            condition: .logical(operation: .and(
                lhs: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .targetStatesEn))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                rhs: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .targetStatesBusy))),
                    rhs: .literal(value: .bit(value: .low))
                )))
            )),
            ifBlock: .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .statesIndex))),
                    rhs: .literal(value: .integer(value: maxIndex))
                ))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .internalState)),
                    value: .reference(variable: .variable(reference: .variable(name: .error)))
                )),
                elseBlock: .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .ringletIndex))),
                        rhs: .literal(value: .integer(value: executionMaxIndex))
                    ))),
                    ifBlock: .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .internalState)),
                        value: .reference(variable: .variable(
                            reference: .variable(name: .waitForCacheToEnd)
                        ))
                    )),
                    elseBlock: .ifStatement(block: .ifElse(
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .indexed(
                                name: .reference(variable: .indexed(
                                    name: .reference(variable: .variable(
                                        reference: .variable(name: .ringlets)
                                    )),
                                    index: .index(value: .reference(variable: .variable(
                                        reference: .variable(name: .ringletIndex)
                                    )))
                                )),
                                index: .index(value: .literal(value: .integer(value: observedIndex)))
                            )),
                            rhs: .literal(value: .bit(value: .high))
                        ))),
                        ifBlock: .ifStatement(block: .ifElse(
                            condition: .conditional(condition: .comparison(value: .greaterThan(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .statesIndex)
                                )),
                                rhs: .cast(operation: .unsigned(expression: .reference(
                                    variable: .variable(reference: .variable(name: .targetStatesLastAddress))
                                )))
                            ))),
                            ifBlock: .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(variable: .variable(
                                    reference: .variable(name: .addToStates)
                                ))
                            )),
                            elseBlock: .ifStatement(block: .ifElse(
                                condition: .conditional(condition: .comparison(value: .equality(
                                    lhs: .reference(variable: .variable(reference: .variable(
                                        name: .targetStatesValueEn
                                    ))),
                                    rhs: .literal(value: .bit(value: .high))
                                ))),
                                ifBlock: .ifStatement(block: .ifElse(
                                    condition: .conditional(condition: .comparison(value: .equality(
                                        lhs: .reference(variable: .variable(
                                            reference: .variable(name: .targetStatesValue)
                                        )),
                                        rhs: writeSnapshot.reducedEncoding(
                                            for: .reference(variable: .indexed(
                                                name: .reference(variable: .variable(
                                                    reference: .variable(name: .ringlets)
                                                )),
                                                index: .index(value: .reference(
                                                    variable: .variable(
                                                        reference: .variable(name: .ringletIndex)
                                                    )
                                                ))
                                            )),
                                            offset: readBits,
                                            ignoring: [.nextState]
                                        )
                                    ))),
                                    ifBlock: .blocks(blocks: [
                                        .statement(statement: .assignment(
                                            name: .variable(reference: .variable(name: .statesIndex)),
                                            value: .literal(value: .vector(value: .indexed(
                                                values: IndexedVector(
                                                    values: [
                                                        IndexedValue(index: .others, value: .bit(value: .low))
                                                    ]
                                                )
                                            )))
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
                                    ]),
                                    elseBlock: .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .statesIndex)),
                                        value: .binary(operation: .addition(
                                            lhs: .reference(variable: .variable(
                                                reference: .variable(name: .statesIndex)
                                            )),
                                            rhs: .literal(value: .integer(value: 1))
                                        ))
                                    ))
                                )),
                                elseBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .statesIndex)),
                                    value: .binary(operation: .addition(
                                        lhs: .reference(variable: .variable(
                                            reference: .variable(name: .statesIndex)
                                        )),
                                        rhs: .literal(value: .integer(value: 1))
                                    ))
                                ))
                            ))
                        )),
                        elseBlock: .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .ringletIndex)),
                            value: .binary(operation: .addition(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .ringletIndex)
                                )),
                                rhs: .literal(value: .integer(value: 1))
                            ))
                        ))
                    ))
                ))
            ))
        ))
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .checkForDuplicates)
            ))),
            code: .blocks(blocks: [
                ifStatement,
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .cacheRead)),
                    value: .literal(value: .boolean(value: false))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .startGeneration)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .startCache)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .targetStatesWe)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .targetStatesReady)),
                    value: .literal(value: .bit(value: .high))
                ))
            ])
        )
    }

    init?<T>(
        stateGeneratorCheckForDuplicatesFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let maxIndex = machine.numberOfTargetStates
        let observedIndex = state.encodedSize(in: representation) - 1
        guard let executionMaxIndex = state.executionSize(
            in: representation, maxExecutionSize: maxExecutionSize
        ).size else {
            return nil
        }
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        // let startIndex = readSnapshot.encodedBits
        // let range = VectorSize.to(
        //     lower: .literal(value: .integer(value: startIndex)),
        //     upper: .literal(value: .integer(value: state.encodedSize(in: representation) - 1))
        // )
        let readBits = readSnapshot.encodedBits
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .checkForDuplicates)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .statesIndex))),
                        rhs: .literal(value: .integer(value: maxIndex))
                    ))),
                    ifBlock: .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .internalState)),
                        value: .reference(variable: .variable(reference: .variable(name: .error)))
                    )),
                    elseBlock: .ifStatement(block: .ifElse(
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .ringletIndex))),
                            rhs: .literal(value: .integer(value: executionMaxIndex))
                        ))),
                        ifBlock: .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .internalState)),
                            value: .reference(variable: .variable(
                                reference: .variable(name: .waitForCacheToEnd)
                            ))
                        )),
                        elseBlock: .ifStatement(block: .ifElse(
                            condition: .conditional(condition: .comparison(value: .equality(
                                lhs: .reference(variable: .indexed(
                                    name: .reference(variable: .indexed(
                                        name: .reference(variable: .variable(
                                            reference: .variable(name: .ringlets)
                                        )),
                                        index: .index(value: .reference(variable: .variable(
                                            reference: .variable(name: .ringletIndex)
                                        )))
                                    )),
                                    index: .index(value: .literal(value: .integer(value: observedIndex)))
                                )),
                                rhs: .literal(value: .bit(value: .high))
                            ))),
                            ifBlock: .blocks(blocks: [
                                .forLoop(loop: ForLoop(
                                    iterator: .i,
                                    range: .to(
                                        lower: .literal(value: .integer(value: 0)),
                                        upper: .literal(value: .integer(value: max(0, maxIndex - 2)))
                                    ),
                                    body: .ifStatement(block: .ifStatement(
                                        condition: .conditional(condition: .comparison(value: .equality(
                                            lhs: .reference(variable: .indexed(
                                                name: .reference(variable: .indexed(
                                                    name: .reference(variable: .variable(
                                                        reference: .variable(name: .states)
                                                    )),
                                                    index: .index(value: .reference(variable: .variable(
                                                        reference: .variable(name: .i)
                                                    )))
                                                )),
                                                index: .index(value: .literal(value: .integer(value: 0)))
                                            )),
                                            rhs: .literal(value: .bit(value: .high))
                                        ))),
                                        ifBlock: .ifStatement(block: .ifStatement(
                                            condition: .conditional(condition: .comparison(value: .equality(
                                                lhs: .reference(variable: .indexed(
                                                    name: .reference(variable: .variable(
                                                        reference: .variable(name: .states)
                                                    )),
                                                    index: .index(value: .reference(variable: .variable(
                                                        reference: .variable(name: .i)
                                                    )))
                                                )),
                                                rhs: .binary(operation: .concatenate(
                                                    lhs: writeSnapshot.reducedEncoding(
                                                        for: .reference(variable: .indexed(
                                                            name: .reference(variable: .variable(
                                                                reference: .variable(name: .ringlets)
                                                            )),
                                                            index: .index(value: .reference(
                                                                variable: .variable(
                                                                    reference: .variable(name: .ringletIndex)
                                                                )
                                                            ))
                                                        )),
                                                        offset: readBits,
                                                        ignoring: [.nextState]
                                                    ),
                                                    rhs: .literal(value: .bit(value: .high))
                                                ))
                                            ))),
                                            ifBlock: .statement(statement: .assignment(
                                                name: .variable(reference: .variable(name: .hasDuplicate)),
                                                value: .literal(value: .boolean(value: true))
                                            ))
                                        ))
                                    ))
                                )),
                                .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .internalState)),
                                    value: .reference(variable: .variable(
                                        reference: .variable(name: .addToStates)
                                    ))
                                ))
                            ]),
                            elseBlock: .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .ringletIndex)),
                                value: .binary(operation: .addition(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .ringletIndex)
                                    )),
                                    rhs: .literal(value: .integer(value: 1))
                                ))
                            ))
                        ))
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .cacheRead)),
                    value: .literal(value: .boolean(value: false))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .startGeneration)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .startCache)),
                    value: .literal(value: .bit(value: .low))
                ))
            ])
        )
    }

}
