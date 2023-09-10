// ProcessBlockTests.swift
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

@testable import VHDLKripkeStructureGenerator
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for `ProcessBlock` extensions.
final class ProcessBlockTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    // swiftlint:enable implicitly_unwrapped_optional

    /// Initialise the test data before every test.
    override func setUp() {
        machine = Machine.initial(
            path: URL(fileURLWithPath: "/path/to/M.machine", isDirectory: true)
        )
    }

    // swiftlint:disable function_body_length

    /// Test the verifiable init creates the new process block correctly.
    func testVerifiableInit() {
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y, mode: .output)
        ]
        guard !machine.states.isEmpty else {
            XCTFail("Machine has no states.")
            return
        }
        machine.states[0].externalVariables = [.x, .y]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
        let y2 = LocalSignal(type: .stdLogic, name: .y2)
        machine.machineSignals = [y2]
        guard let representation = MachineRepresentation(machine: machine) else {
            XCTFail("Failed to create representation.")
            return
        }
        let body = representation.architectureBody
        guard
            case .process(let process) = body,
            case .ifStatement(let block) = process.code,
            case .ifStatement(let condition, let logic) = block,
            case .conditional(let operation) = condition,
            case .edge(value: let edge) = operation,
            case .rising(let expression) = edge,
            case .reference(let ref) = expression,
            case .variable(let nameRef) = ref,
            case .variable(let name) = nameRef,
            machine.drivingClock < machine.clocks.count,
            name == machine.clocks[machine.drivingClock].name,
            let newInitialX = VariableName(rawValue: "STATE_Initial_initialX")
        else {
            XCTFail("Invalid architecture body.")
            return
        }
        let clk = machine.clocks[machine.drivingClock].name
        let newVariables = [
            (VariableName.internalState, VariableName.internalStateOut(for: machine)),
            (VariableName.targetState, VariableName.targetStateOut(for: machine)),
            (VariableName.currentState, VariableName.currentStateOut(for: machine)),
            (VariableName.previousRinglet, VariableName.previousRingletOut(for: machine))
        ]
        let newLogic = newVariables.reduce(logic) {
            SynchronousBlock(internalSignal: $0, signal: $1.0, newSignal: $1.1)
        }
        guard let mutationBlock = SynchronousBlock.internalMutation(for: machine) else {
            XCTFail("Failed to create mutation block.")
            return
        }
        let expectedLogic = SynchronousBlock.ifStatement(block: .ifStatement(
            condition: .conditional(
                condition: .edge(value: .rising(expression: .reference(
                    variable: .variable(reference: .variable(name: clk))
                )))
            ),
            ifBlock: .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .reset))),
                    rhs: .literal(value: .logic(value: .high))
                ))),
                ifBlock: .blocks(
                    blocks: [
                        SynchronousBlock.statement(statement: .assignment(
                            name: .variable(reference: .variable(name: VariableName(
                                portNameFor: LocalSignal(type: .stdLogic, name: .y), in: machine
                            ))),
                            value: .reference(variable: .variable(reference: .variable(name: .y)))
                        )),
                        SynchronousBlock.statement(statement: .assignment(
                            name: .variable(reference: .variable(name: VariableName(
                                portNameFor: y2, in: machine
                            ))),
                            value: .reference(variable: .variable(reference: .variable(name: y2.name)))
                        )),
                        SynchronousBlock.statement(statement: .assignment(
                            name: .variable(reference: .variable(name: VariableName(
                                portNameFor: LocalSignal(type: .stdLogic, name: newInitialX), in: machine
                            ))),
                            value: .reference(variable: .variable(reference: .variable(name: newInitialX)))
                        ))
                    ] + [newLogic]
                ),
                elseBlock: mutationBlock
            ))
        ))
        let expected = ProcessBlock(sensitivityList: [clk], code: expectedLogic)
        guard let newProcess = ProcessBlock(verifiable: process, in: machine) else {
            XCTFail("Failed to construct new process.")
            return
        }
        XCTAssertEqual(expected, newProcess)
    }

    // swiftlint:enable function_body_length

    /// Test that the verifiable init returns nil for an invalid process.
    func testVerifiableInitReturnsNilForInvalidProcess() {
        let process = ProcessBlock(sensitivityList: [], code: .statement(statement: .null))
        XCTAssertNil(ProcessBlock(verifiable: process, in: machine))
    }

}
