// WhenCase+waitForNewRinglets.swift
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

import VHDLMachines
import VHDLParsing

extension WhenCase {

    init<T>(
        ringletCacheSmallWaitForNewRingletsFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let indexes = readSnapshot.encodedIndexes
        let readExternals = Set(
            representation.machine.externalSignals.filter { $0.mode != .output }.map(\.name)
        )
        let invalidExternals = Set(state.externalVariables.filter { !readExternals.contains($0) })
        let validIndexes = indexes.filter { !invalidExternals.contains($0.0.name) }
        let condition = validIndexes.map {
            Expression.conditional(condition: .comparison(value: .notEquals(
                lhs: .reference(variable: .indexed(
                    name: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .newRinglets))),
                        index: .index(value: .literal(value: .integer(value: 0)))
                    )),
                    index: $0.1
                )),
                rhs: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "last_\($0.0.name.rawValue)")!
                )))
            )))
        } + [.reference(variable: .variable(reference: .variable(name: .isInitial)))]
        let conditionReduced = condition.joined { .logical(operation: .or(lhs: $0, rhs: $1)) }
        let assignments = validIndexes.map {
            SynchronousBlock.statement(statement: Statement.assignment(
                name: .variable(reference: .variable(
                    name: VariableName(rawValue: "last_\($0.0.name.rawValue)")!
                )),
                value: .reference(variable: .indexed(
                    name: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .newRinglets))),
                        index: .index(value: .literal(value: .integer(value: 0)))
                    )),
                    index: $0.1
                ))
            ))
        }
        let ifBlock = SynchronousBlock.blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .writeElement)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            ))
        ] + assignments + [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .workingRinglets)),
                value: .reference(variable: .variable(reference: .variable(name: .newRinglets)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .isInitial)),
                value: .literal(value: .boolean(value: false))
            ))
        ])
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .waitForNewRinglets)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                        rhs: .literal(value: .bit(value: .high))
                    ))),
                    ifBlock: .ifStatement(block: .ifElse(
                        condition: .logical(operation: .not(value: .reference(variable: .variable(
                            reference: .variable(name: .read)
                        )))),
                        ifBlock: .ifStatement(block: .ifElse(
                            condition: conditionReduced,
                            ifBlock: ifBlock,
                            elseBlock: .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .busy)),
                                value: .literal(value: .bit(value: .low))
                            ))
                        )),
                        elseBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .busy)),
                                value: .literal(value: .bit(value: .low))
                            )),
                            .ifStatement(block: .ifElse(
                                condition: .conditional(condition: .comparison(value: .equality(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .readAddress)
                                    )),
                                    rhs: .reference(variable: .variable(
                                        reference: .variable(name: .currentRingletAddress)
                                    ))
                                ))),
                                ifBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .value)),
                                    value: state.entireCache(in: representation)
                                )),
                                elseBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .value)),
                                    value: .reference(variable: .variable(
                                        reference: .variable(name: .cacheValue)
                                    ))
                                ))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .index)),
                                value: .reference(variable: .variable(
                                    reference: .variable(name: .readAddress)
                                ))
                            ))
                        ])
                    )),
                    elseBlock: .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .low))
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .ringletIndex)),
                    value: .literal(value: .integer(value: 0))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .we)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .isDuplicate)),
                    value: .literal(value: .boolean(value: false))
                ))
            ])
        )
    }

    init<T>(
        ringletCacheLargeWaitForNewRingletsFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let ifBlock = SynchronousBlock.blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .writeElement)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .workingRinglets)),
                value: .reference(variable: .variable(reference: .variable(name: .newRinglets)))
            ))
        ])
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .waitForNewRinglets)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .logical(operation: .and(
                        lhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                            rhs: .literal(value: .bit(value: .high))
                        ))),
                        rhs: .logical(operation: .not(value: .reference(variable: .variable(
                            reference: .variable(name: .read)
                        ))))
                    )),
                    ifBlock: ifBlock,
                    elseBlock: .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .low))
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .ringletIndex)),
                    value: .literal(value: .integer(value: 0))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .we)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .isDuplicate)),
                    value: .literal(value: .boolean(value: false))
                ))
            ])
        )
    }

}
