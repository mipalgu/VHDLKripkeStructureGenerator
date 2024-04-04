// VariableNameTests.swift
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

/// Test class for ``VariableName`` extensions.
final class VariableNameTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use as test data.
    let machine: Machine! = Machine.initialSuspensible

    /// The representation of the `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine, name: .M)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// Test that the constants are correct with the given machine name.
    func testStaticConstants() {
        XCTAssertEqual(VariableName.internalState.rawValue, "internalState")
        XCTAssertEqual(VariableName.currentState.rawValue, "currentState")
        XCTAssertEqual(VariableName.previousRinglet.rawValue, "previousRinglet")
        XCTAssertEqual(VariableName.primitiveTypes.rawValue, "PrimitiveTypes")
        XCTAssertEqual(VariableName.reset.rawValue, "reset")
        XCTAssertEqual(VariableName.setInternalSignals.rawValue, "setInternalSignals")
        XCTAssertEqual(VariableName.stdLogicTypes.rawValue, "stdLogicTypes")
        XCTAssertEqual(VariableName.stdLogicTypesT.rawValue, "stdLogicTypes_t")
        XCTAssertEqual(VariableName.targetState.rawValue, "targetState")
        XCTAssertEqual(VariableName.currentStateIn(for: representation).rawValue, "M_currentStateIn")
        XCTAssertEqual(VariableName.currentStateOut(for: representation).rawValue, "M_currentStateOut")
        XCTAssertEqual(VariableName.internalStateIn(for: representation).rawValue, "M_internalStateIn")
        XCTAssertEqual(VariableName.internalStateOut(for: representation).rawValue, "M_internalStateOut")
        XCTAssertEqual(VariableName.previousRingletIn(for: representation).rawValue, "M_previousRingletIn")
        XCTAssertEqual(VariableName.previousRingletOut(for: representation).rawValue, "M_previousRingletOut")
        XCTAssertEqual(VariableName.targetStateIn(for: representation).rawValue, "M_targetStateIn")
        XCTAssertEqual(VariableName.targetStateOut(for: representation).rawValue, "M_targetStateOut")
    }

    /// Tests that the port name is created correctly from the local signal and machine name.
    func testPortNameInit() {
        guard let signalName = VariableName(rawValue: "x") else {
            XCTFail("Failed to create signal name.")
            return
        }
        let signal = LocalSignal(type: .stdLogic, name: signalName)
        let portName = VariableName(portNameFor: signal, in: representation)
        XCTAssertEqual(portName.rawValue, "M_x")
    }

    /// Test that pre prepends string correctly.
    func testPreInit() {
        let expected = VariableName(rawValue: "M_x")
        let result = VariableName(pre: "M_", name: .x)
        XCTAssertNotNil(result)
        XCTAssertEqual(expected, result)
    }

    /// Test that post appends string correctly.
    func testPostInit() {
        let expected = VariableName(rawValue: "xIn")
        let result = VariableName(name: .x, post: "In")
        XCTAssertNotNil(result)
        XCTAssertEqual(expected, result)
    }

    /// Test that pre and post modify string correctly.
    func testPrePostInit() {
        let expected = VariableName(rawValue: "M_xIn")
        let result = VariableName(pre: "M_", name: .x, post: "In")
        XCTAssertNotNil(result)
        XCTAssertEqual(expected, result)
    }

}
