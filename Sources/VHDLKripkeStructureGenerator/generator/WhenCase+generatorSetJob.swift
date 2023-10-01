// WhenCase+generatorSetJob.swift
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

    init?<T>(generatorSetJobFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let endPendingIndex = machine.numberOfPendingStates
        let numberOfStateBits = machine.numberOfStateBits
        let stateIndex = VectorIndex.range(value: .downto(
            upper: .literal(value: .integer(value: numberOfStateBits + 1)),
            lower: .literal(value: .integer(value: 2))
        ))
        let stateLogics = machine.states.map {
            let name = $0.name.rawValue
            return SynchronousBlock.ifStatement(block: .ifStatement(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .indexed(
                        name: .reference(variable: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .pendingStates))),
                            index: .index(value: .reference(variable: .variable(
                                reference: .variable(name: .pendingStateIndex)
                            )))
                        )),
                        index: stateIndex
                    )),
                    rhs: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "STATE_\(name)")!
                    )))
                ))),
                ifBlock: .blocks(blocks: [
                    .ifStatement(block: .ifElse(
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(
                                name: VariableName(rawValue: "\(name)Busy")!
                            ))),
                            rhs: .literal(value: .bit(value: .low))
                        ))),
                        ifBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .nextState)),
                                value: .reference(variable: .variable(reference: .variable(
                                    name: VariableName(rawValue: "Start\(name)")!
                                )))
                            )),
                            .ifStatement(block: .ifElse(
                                condition: .reference(variable: .variable(
                                    reference: .variable(name: VariableName(rawValue: "\(name)Working")!)
                                )),
                                ifBlock: .blocks(blocks: [
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .fromState)),
                                        value: .reference(variable: .variable(
                                            reference: .variable(
                                                name: VariableName(rawValue: "Update\(name)PendingStates")!
                                            )
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(name: .currentState)),
                                        value: .reference(variable: .variable(
                                            reference: .variable(name: .chooseNextInsertion)
                                        ))
                                    )),
                                    .statement(statement: .assignment(
                                        name: .variable(reference: .variable(
                                            name: VariableName(rawValue: "\(name)Index")!
                                        )),
                                        value: .literal(value: .integer(value: 0))
                                    ))
                                ]),
                                elseBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .currentState)),
                                    value: .reference(variable: .variable(
                                        reference: .variable(name: .checkForDuplicate)
                                    ))
                                ))
                            ))
                        ]),
                        elseBlock: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .nextState)),
                                value: .reference(variable: .variable(reference: .variable(name: .setJob)))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .currentState)),
                                value: .reference(variable: .variable(
                                    reference: .variable(name: .checkIfFinished)
                                ))
                            ))
                        ])
                    ))
                ])
            ))
        } + [
            SynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(name: .nextState)),
                value: .reference(variable: .variable(reference: .variable(name: .setJob)))
            ))
        ]
        let combinedStateLogic = stateLogics.reversed().joined {
            guard case .ifStatement(let block) = $1, case .ifStatement(let condition, let code) = block else {
                fatalError("Invalid state logic format, found: \($1).")
            }
            return SynchronousBlock.ifStatement(block: .ifElse(
                condition: condition,
                ifBlock: code,
                elseBlock: $0
            ))
        }
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .setJob)
            ))),
            code: .blocks(blocks: [
                .ifStatement(block: .ifElse(
                    condition: .logical(operation: .or(
                        lhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(
                                reference: .variable(name: .pendingStateIndex)
                            )),
                            rhs: .literal(value: .integer(value: endPendingIndex))
                        ))),
                        rhs: .conditional(condition: .comparison(value: .greaterThan(
                            lhs: .reference(variable: .variable(
                                reference: .variable(name: .pendingStateIndex)
                            )),
                            rhs: .reference(variable: .variable(reference: .variable(name: .maxInsertIndex)))
                        )))
                    )),
                    ifBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .currentState)),
                            value: .reference(variable: .variable(
                                reference: .variable(name: .checkIfFinished)
                            ))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .pendingStateIndex)),
                            value: .literal(value: .integer(value: 0))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .isFinished)),
                            value: .literal(value: .boolean(value: true))
                        ))
                    ]),
                    elseBlock: .ifStatement(block: .ifElse(
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .indexed(
                                name: .reference(variable: .indexed(
                                    name: .reference(variable: .variable(
                                        reference: .variable(name: .pendingStates)
                                    )),
                                    index: .index(value: .reference(variable: .variable(
                                        reference: .variable(name: .pendingStateIndex)
                                    )))
                                )),
                                index: .index(value: .literal(value: .integer(value: 0)))
                            )),
                            rhs: .literal(value: .bit(value: .high))
                        ))),
                        ifBlock: combinedStateLogic,
                        elseBlock: .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .pendingStateIndex)),
                            value: .binary(operation: .addition(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .pendingStateIndex)
                                )),
                                rhs: .literal(value: .integer(value: 1))
                            ))
                        ))
                    ))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .isDuplicate)),
                    value: .literal(value: .boolean(value: false))
                ))
            ])
        )
    }

}
