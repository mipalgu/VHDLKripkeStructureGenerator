// SynchronousBlockTests.swift
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

@testable import VHDLGenerator
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for `SynchronousBlock` extensions.
final class SynchronousBlockTests: XCTestCase {

    /// A machine to use for testing.
    var machine: Machine = Machine.initialSuspensible

    /// The varaible `x`.
    let x = Expression.reference(variable: .variable(reference: .variable(name: .x)))

    // swiftlint:disable implicitly_unwrapped_optional

    /// The representation of the machine.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine, name: .M)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initialSuspensible
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
    }

    // swiftlint:disable function_body_length

    /// Test that init(internalSignal:, signal:, newSignal:) adds in additional statements correctly.
    func testReplaceInit() {
        let block = SynchronousBlock.blocks(blocks: [
            .caseStatement(block: CaseStatement(
                condition: .reference(variable: .variable(reference: .variable(name: .x))),
                cases: [
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .forLoop(loop: ForLoop(
                            iterator: .x,
                            range: .downto(
                                upper: .reference(variable: .variable(reference: .variable(name: .x))),
                                lower: .reference(variable: .variable(reference: .variable(name: .x)))
                            ),
                            body: .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .x)),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            ))
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .ifStatement(block: .ifElse(
                            condition: .reference(variable: .variable(reference: .variable(name: .x))),
                            ifBlock: .statement(statement: .assignment(
                                name: .indexed(
                                    name: x, index: .index(value: .reference(
                                        variable: .variable(reference: .variable(name: .x))
                                    ))
                                ),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            )),
                            elseBlock: .statement(statement: .assignment(
                                name: .indexed(name: x, index: .range(value: .to(
                                    lower: .reference(variable: .variable(reference: .variable(name: .x))),
                                    upper: .reference(variable: .variable(reference: .variable(name: .x)))
                                ))),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            ))
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .ifStatement(block: .ifStatement(
                            condition: .reference(variable: .variable(reference: .variable(name: .x))),
                            ifBlock: .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .x)),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            ))
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .x)),
                            value: .reference(variable: .variable(reference: .variable(name: .x)))
                        ))
                    ),
                    WhenCase(condition: .others, code: .statement(statement: .null))
                ]
            ))
        ])
        let expected = SynchronousBlock.blocks(blocks: [
            .caseStatement(block: CaseStatement(
                condition: .reference(variable: .variable(reference: .variable(name: .x))),
                cases: [
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .forLoop(loop: ForLoop(
                            iterator: .x,
                            range: .downto(
                                upper: .reference(variable: .variable(reference: .variable(name: .x))),
                                lower: .reference(variable: .variable(reference: .variable(name: .x)))
                            ),
                            body: .blocks(blocks: [
                                .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .x)),
                                    value: .reference(variable: .variable(reference: .variable(name: .x)))
                                )),
                                .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .y)),
                                    value: .reference(variable: .variable(reference: .variable(name: .x)))
                                ))
                            ])
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .ifStatement(block: .ifElse(
                            condition: .reference(variable: .variable(reference: .variable(name: .x))),
                            ifBlock: .statement(statement: .assignment(
                                name: .indexed(
                                    name: x, index: .index(value: .reference(
                                        variable: .variable(reference: .variable(name: .x))
                                    ))
                                ),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            )),
                            elseBlock: .statement(statement: .assignment(
                                name: .indexed(name: x, index: .range(value: .to(
                                    lower: .reference(variable: .variable(reference: .variable(name: .x))),
                                    upper: .reference(variable: .variable(reference: .variable(name: .x)))
                                ))),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            ))
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .ifStatement(block: .ifStatement(
                            condition: .reference(variable: .variable(reference: .variable(name: .x))),
                            ifBlock: .blocks(blocks: [
                                .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .x)),
                                    value: .reference(variable: .variable(reference: .variable(name: .x)))
                                )),
                                .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .y)),
                                    value: .reference(variable: .variable(reference: .variable(name: .x)))
                                ))
                            ])
                        ))
                    ),
                    WhenCase(
                        condition: .expression(expression: .reference(
                            variable: .variable(reference: .variable(name: .x))
                        )),
                        code: .blocks(blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .x)),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .y)),
                                value: .reference(variable: .variable(reference: .variable(name: .x)))
                            ))
                        ])
                    ),
                    WhenCase(condition: .others, code: .statement(statement: .null))
                ]
            ))
        ])
        let result = SynchronousBlock(internalSignal: block, signal: .x, newSignal: .y)
        XCTAssertEqual(result, expected, result.rawValue)
    }

    // swiftlint:enable function_body_length

    /// Test that internal mutation block is created correctly.
    func testInternalMutation() {
        guard let result = SynchronousBlock.internalMutation(for: representation) else {
            XCTFail("Failed to create block!")
            return
        }
        let expected = """
        if (setInternalSignals = '1') then
            currentState <= M_currentStateIn;
            previousRinglet <= M_previousRingletIn;
            internalState <= M_internalStateIn;
            targetState <= M_targetStateIn;
            M_currentStateOut <= M_currentStateIn;
            M_previousRingletOut <= M_previousRingletIn;
            M_internalStateOut <= M_internalStateIn;
            M_targetStateOut <= M_targetStateIn;
            y2 <= M_y2In;
            y <= M_yIn;
            STATE_Initial_initialX <= M_STATE_Initial_initialXIn;
        else
            M_currentStateOut <= currentState;
            M_previousRingletOut <= previousRinglet;
            M_internalStateOut <= internalState;
            M_targetStateOut <= targetState;
            M_y2 <= y2;
            M_y <= y;
            M_STATE_Initial_initialX <= STATE_Initial_initialX;
        end if;
        """
        XCTAssertEqual(result.rawValue, expected)
    }

}
