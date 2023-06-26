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

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initial(path: URL(fileURLWithPath: "/path/to/M.machine", isDirectory: true))
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
        XCTAssertFalse(AsynchronousBlock.statement(statement: .null).hasProcess)
        XCTAssertTrue(
            AsynchronousBlock.blocks(
                blocks: [
                    .statement(statement: .null),
                    .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null)))
                ]
            ).hasProcess
        )
        XCTAssertTrue(
            AsynchronousBlock.blocks(blocks: [
                .blocks(blocks: [
                    .statement(statement: .null),
                    .process(block: ProcessBlock(sensitivityList: [], code: .statement(statement: .null)))
                ]),
                .statement(statement: .null)
            ]).hasProcess
        )
    }

    func testVerifiableProcess() {
        guard
            let representation,
            case .process(let process) = representation.architectureBody,
            let newProcess = ProcessBlock(verifiable: process, in: representation.machine)
        else {
            XCTFail("Not a process!")
            return
        }
        XCTAssertEqual(
            AsynchronousBlock(verifiable: representation.architectureBody, in: representation.machine),
            AsynchronousBlock.process(block: newProcess)
        )
    }

    func testVerifiableBlocks() {
        guard
            let representation,
            case .process(let process) = representation.architectureBody,
            let newProcess = ProcessBlock(verifiable: process, in: representation.machine)
        else {
            XCTFail("Not a process!")
            return
        }
        let nullStatement = AsynchronousBlock.statement(statement: .null)
        let blocks = AsynchronousBlock.blocks(
            blocks: [nullStatement, representation.architectureBody]
        )
        let expected = AsynchronousBlock.blocks(blocks: [nullStatement, .process(block: newProcess)])
        XCTAssertEqual(AsynchronousBlock(verifiable: blocks, in: representation.machine), expected)
    }

    func testVerifiableRepresentation() {
        guard let representation, let block = AsynchronousBlock(verifiable: representation) else {
            XCTFail("Invalid representation")
            return
        }
        // block.rawValue.components(separatedBy: .newlines).forEach { print($0) }
    }

}
