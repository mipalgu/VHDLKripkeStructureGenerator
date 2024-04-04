// AsynchronousBlockTests.swift
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

/// Test class for `AsynchronousBlock` extensions.
final class AsynchronousBlockTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A comment.
    let comment = AsynchronousBlock.statement(
        // swiftlint:disable:next force_unwrapping
        statement: .comment(value: Comment(rawValue: "-- This is a comment")!)
    )

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
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
    }

    /// Test that the `hasProcess` computed property correctly detects process blocks.
    func testHasProcess() {
        XCTAssertTrue(
            AsynchronousBlock.process(
                block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null))
            ).hasProcess
        )
        XCTAssertFalse(comment.hasProcess)
        XCTAssertTrue(
            AsynchronousBlock.blocks(
                blocks: [
                    comment,
                    .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null)))
                ]
            ).hasProcess
        )
        XCTAssertTrue(
            AsynchronousBlock.blocks(blocks: [
                .blocks(blocks: [
                    comment,
                    .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null)))
                ]),
                comment
            ]).hasProcess
        )
    }

    /// Test verifiable process is created correctly.
    func testVerifiableProcess() {
        guard
            let representation,
            case .process(let process) = representation.architectureBody,
            let newProcess = ProcessBlock(verifiable: process, in: representation)
        else {
            XCTFail("Not a process!")
            return
        }
        XCTAssertEqual(
            AsynchronousBlock(verifiable: representation.architectureBody, in: representation),
            AsynchronousBlock.process(block: newProcess)
        )
    }

    /// Test that only the process is changed in the blocks.
    func testVerifiableBlocks() {
        guard
            let representation,
            case .process(let process) = representation.architectureBody,
            let newProcess = ProcessBlock(verifiable: process, in: representation)
        else {
            XCTFail("Not a process!")
            return
        }
        let nullStatement = comment
        let blocks = AsynchronousBlock.blocks(
            blocks: [nullStatement, representation.architectureBody]
        )
        let expected = AsynchronousBlock.blocks(blocks: [nullStatement, .process(block: newProcess)])
        XCTAssertEqual(AsynchronousBlock(verifiable: blocks, in: representation), expected)
    }

    /// Test init returns nil when `ProcessBlock.init(verifiable:in:)` returns nil.
    func testVerifiableProcessReturnsNil() {
        let block = AsynchronousBlock.process(
            block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null))
        )
        XCTAssertNil(AsynchronousBlock(verifiable: block, in: representation))
    }

    /// Test blocks return nil when containing invalid process.
    func testVerifiableBlocksReturnsNil() {
        let blocks = AsynchronousBlock.blocks(blocks: [
            comment,
            .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null)))
        ])
        XCTAssertNil(AsynchronousBlock(verifiable: blocks, in: representation))
    }

    /// Test init returns nil without a process.
    func testVerifiableReturnsNilForInvalidRepresentation() {
        XCTAssertNil(AsynchronousBlock(verifiable: NullRepresentation()))
    }

    /// Test init returns nil for incorrect process.
    func testVerifiableReturnsNilForInvalidProcess() {
        XCTAssertNil(AsynchronousBlock(verifiable: NullRepresentation(
            body: .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null))),
            machine: machine
        )))
    }

    /// Test init returns nil for components and statements.
    func testVerifiableReturnsNilForComponentAndStatement() {
        XCTAssertNil(AsynchronousBlock(
            verifiable: NullRepresentation(
                body: .component(block: ComponentInstantiation(
                    label: .y, name: .y2, port: PortMap(variables: [])
                )),
                machine: machine
            )
        ))
        XCTAssertNil(AsynchronousBlock(
            verifiable: NullRepresentation(body: comment, machine: machine)
        ))
    }

    /// Test init returns nil for invalid process in blocks.
    func testBlocksReturnsNilWhenInitFailsInVerifiable() {
        XCTAssertNil(AsynchronousBlock(verifiable: NullRepresentation(
            body: .blocks(blocks: [
                comment,
                .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null)))
            ]),
            machine: machine
        )))
    }

    /// Test init correctly creates a process from a valid machine blocks format.
    func testBlocksWorksForValidMachineFormat() {
        machine.architectureBody = comment
        guard
            let representation,
            case .blocks(let blocks) = representation.architectureBody,
            blocks.count == 3,
            case .statement(statement: .comment) = blocks[0],
            case .process(let process) = blocks[2],
            let verifiableProcess = ProcessBlock(verifiable: process, in: representation),
            let xName = VariableName(rawValue: "M_x")
        else {
            XCTFail("Not a block!")
            return
        }
        let expected = AsynchronousBlock.blocks(
            blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: xName)),
                    value: .expression(value: .reference(variable: .variable(reference: .variable(name: .x))))
                )),
                blocks[0],
                comment,
                .process(block: verifiableProcess)
            ]
        )
        let result = AsynchronousBlock(verifiable: representation)
        XCTAssertEqual(result, expected)
    }

}
