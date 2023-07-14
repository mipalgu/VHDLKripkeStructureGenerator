// VHDLFileTests.swift
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

/// Test class for ``VHDLFile`` extensions.
final class VHDLFileTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use as test data.
    var machine: Machine!

    // swiftlint:enable implicitly_unwrapped_optional

    /// Initialise the test data before every test.
    override func setUp() {
        machine = Machine.initial(path: URL(fileURLWithPath: "/tmp/M.machine", isDirectory: true))
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
    }

    /// Test the `PrimitiveTypes` file is generated correctly.
    func testPrimitiveTypes() {
        // swiftlint:disable line_length
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        package PrimitiveTypes is
            type stdLogicTypes_t is array (0 to 8) of std_logic;
            constant stdLogicTypes: stdLogicTypes_t := (0 => 'U', 1 => 'X', 2 => '0', 3 => '1', 4 => 'Z', 5 => 'W', 6 => 'L', 7 => 'H', 8 => '-');
        end package PrimitiveTypes;

        """
        // swiftlint:enable line_length
        XCTAssertEqual(VHDLFile.primitiveTypes.rawValue, expected)
    }

    /// Test verifiable init returns nil for invalid Port and body.
    func testVerifiableInitReturnsNilForInvalidPortAndBody() {
        XCTAssertNil(VHDLFile(verifiable: NullRepresentation()))
        XCTAssertNil(VHDLFile(verifiable: NullRepresentation(machine: machine)))
    }

    /// Test verifiable init creates the correct file.
    func testVerifiableInit() {
        guard
            let representation = MachineRepresentation(machine: machine),
            let port = PortBlock(verifiable: representation),
            let body = AsynchronousBlock(verifiable: representation)
        else {
            XCTFail("Failed to create file components!")
            return
        }
        let entity = Entity(name: machine.name, port: port)
        let architecture = Architecture(
            body: body,
            entity: machine.name,
            head: representation.architectureHead,
            name: representation.architectureName
        )
        let expected = VHDLFile(
            architectures: [architecture], entities: [entity], includes: machine.includes, packages: []
        )
        let result = VHDLFile(verifiable: representation)
        XCTAssertEqual(result, expected)
    }

}
