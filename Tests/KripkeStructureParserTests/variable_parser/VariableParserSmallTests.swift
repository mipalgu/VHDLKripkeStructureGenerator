// VariableParserSmallTests.swift
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

@testable import KripkeStructureParser
import TestUtils
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for ``VariableParser`` small init.
final class VariableParserSmallTests: XCTestCase {

    // swiftlint:disable force_unwrapping

    /// A representation of the `PingMachine`.
    let representation = MachineRepresentation(machine: .pingMachine, name: .pingMachine)!

    // swiftlint:enable force_unwrapping

    /// The parser under test.
    lazy var parser = VariableParser(smallState: .waitForPong, in: representation)

    /// Setup the parser before every test.
    override func setUp() {
        parser = VariableParser(smallState: .waitForPong, in: representation)
    }

    /// Test the definitions are correct.
    func testDefinitions() {
        let result = parser.definitions.sorted { $0.0 < $1.0 }.map { $0.1 }.joined(separator: "\n")
        let expected = """
        bool PingMachine_WaitForPong_READ_executeOnEntry(uint32_t data);
        uint8_t PingMachine_WaitForPong_READ_PingMachine_ping(uint32_t data);
        uint8_t PingMachine_WaitForPong_READ_pong(uint32_t data);
        bool PingMachine_WaitForPong_WRITE_executeOnEntry(uint32_t data);
        uint32_t PingMachine_WaitForPong_WRITE_nextState(uint32_t data);
        uint8_t PingMachine_WaitForPong_WRITE_ping(uint32_t data);
        """
        XCTAssertEqual(result, expected)
    }

}
