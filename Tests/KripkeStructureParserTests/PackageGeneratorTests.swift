// PackageGeneratorTests.swift
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
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for `PackageGenerator`.
final class PackageGeneratorTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional
    // swiftlint:disable force_unwrapping

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine, name: VariableName(rawValue: "M")!)
    }

    // swiftlint:enable force_unwrapping
    // swiftlint:enable implicitly_unwrapped_optional

    /// The raw VHDL for the initial state runner architecture head of `machine`.
    var raw: String {
        """
        """
    }

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initialSuspensible
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output),
            PortSignal(type: .stdLogic, name: VariableName(rawValue: "nullX")!, mode: .input),
            PortSignal(type: .stdLogic, name: VariableName(rawValue: "nullY")!, mode: .output),
            PortSignal(
                type: .ranged(type: .stdLogicVector(size: .downto(
                    upper: .literal(value: .integer(value: 1)), lower: .literal(value: .integer(value: 0))
                ))),
                name: VariableName(rawValue: "nullXs")!,
                mode: .input
            ),
            PortSignal(type: .stdLogic, name: VariableName(rawValue: "y3")!, mode: .output),
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
        machine.states[0].externalVariables = [
            .x, .y2, VariableName(rawValue: "nullXs")!, VariableName(rawValue: "y3")!
        ]
    }

    /// Test that the C file generation creates the same file every time.
    func testCFileContentsIsGeneratedDeterministically() {
        let generator = PackageGenerator()
        guard
            let package1 = generator.swiftPackage(representation: representation),
            let package1CFile = package1
                .fileWrappers?["Sources"]?
                .fileWrappers?["CM"]?
                .fileWrappers?["M.c"]?
                .regularFileContents,
            let package1HFile = package1
                .fileWrappers?["Sources"]?
                .fileWrappers?["CM"]?
                .fileWrappers?["include"]?
                .fileWrappers?["CM"]?
                .fileWrappers?["M.h"]?
                .regularFileContents,
            let package2 = generator.swiftPackage(representation: representation),
            let package2CFile = package2
                .fileWrappers?["Sources"]?
                .fileWrappers?["CM"]?
                .fileWrappers?["M.c"]?
                .regularFileContents,
            let package2HFile = package1
                .fileWrappers?["Sources"]?
                .fileWrappers?["CM"]?
                .fileWrappers?["include"]?
                .fileWrappers?["CM"]?
                .fileWrappers?["M.h"]?
                .regularFileContents,
            let craw1 = String(data: package1CFile, encoding: .utf8),
            let craw2 = String(data: package2CFile, encoding: .utf8),
            let hraw1 = String(data: package1HFile, encoding: .utf8),
            let hraw2 = String(data: package2HFile, encoding: .utf8)
        else {
            XCTFail("failed to get c files.")
            return
        }
        XCTAssertEqual(craw1, craw2)
        XCTAssertEqual(hraw1, hraw2)
    }

}
