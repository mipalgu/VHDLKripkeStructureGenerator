// WhenCase+generatorCheckIfFinished.swift
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

    init<T>(generatorCheckIfFinishedFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let maxIndex = max(0, machine.numberOfTargetStates - 1)
        // let range = VectorSize.to(
        //     lower: .literal(value: .integer(value: 0)), upper: .literal(value: .integer(value: maxIndex))
        // )
        let stateBlocks = machine.states.map {
            let name = $0.name.rawValue
            return SynchronousBlock.ifStatement(block: .ifStatement(
                condition: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "\(name)Working")!
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .isFinished)),
                        value: .literal(value: .boolean(value: false))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .currentState)),
                        value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "Check\(name)Finished")!
                        )))
                    ))
                ])
            ))
        }
        let currentPendingState = Expression.reference(variable: .variable(reference: .variable(
            name: .currentPendingState
        )))
        let pendingSearchIndex = Expression.reference(variable: .variable(reference: .variable(
            name: .pendingSearchIndex
        )))
        let trailer = SynchronousBlock.ifStatement(block: .ifElse(
            condition: .conditional(condition: .comparison(value: .equality(
                lhs: .reference(variable: .indexed(
                    name: currentPendingState, index: .index(value: .literal(value: .integer(value: 0)))
                )),
                rhs: .literal(value: .bit(value: .high))
            ))),
            ifBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .isFinished)),
                    value: .literal(value: .boolean(value: false))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .pendingSearchIndex)),
                    value: .literal(value: .integer(value: 0))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(reference: .variable(name: .verifyFinished)))
                ))
            ]),
            elseBlock: .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: pendingSearchIndex,
                    rhs: .literal(value: .integer(value: (maxIndex + 1) * 2 - 1))
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .currentState)),
                        value: .reference(variable: .variable(reference: .variable(name: .verifyFinished)))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .pendingSearchIndex)),
                        value: .literal(value: .integer(value: 0))
                    ))
                ]),
                elseBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .pendingSearchIndex)),
                    value: .binary(operation: .addition(
                        lhs: pendingSearchIndex,
                        rhs: .literal(value: .integer(value: 1))
                    ))
                ))
            ))
        ))
        let combined = (stateBlocks + [trailer]).reversed().joined {
            guard
                case .ifStatement(let block) = $1, case . ifStatement(let condition, let code) = block
            else {
                fatalError("Incorrect format for state block.")
            }
            return SynchronousBlock.ifStatement(block: .ifElse(
                condition: condition,
                ifBlock: code,
                elseBlock: $0
            ))
        }
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .checkIfFinished)
            ))),
            code: combined
        )
    }

}
