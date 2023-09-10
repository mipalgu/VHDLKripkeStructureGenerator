// PortSignalTests.swift
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

/// Test class for ``PortSignal`` extensions.
final class PortSignalTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use as test data.
    var machine: Machine!

    // swiftlint:enable implicitly_unwrapped_optional

    override func setUp() {
        machine = Machine.initial(
            path: URL(fileURLWithPath: "path/to/M.machine", isDirectory: true)
        )
    }

    /// Test that ``init(currentStateInFor:)`` works correctly.
    func testCurrentStateInInit() {
        let signal = PortSignal(currentStateInFor: machine)
        XCTAssertNotNil(signal)
        XCTAssertEqual(signal?.name, .currentStateIn(for: machine))
        XCTAssertEqual(
            signal?.type,
            .signal(type: .ranged(type: .stdLogicVector(size: .downto(
                upper: .literal(value: .integer(value: 0)), lower: .literal(value: .integer(value: 0))
            ))))
        )
        XCTAssertEqual(signal?.mode, .input)
        XCTAssertEqual(signal, PortSignal(name: .currentStateIn(for: machine), bitsRequired: 1, mode: .input))
        XCTAssertEqual(
            signal, PortSignal(name: .currentStateIn(for: machine), machine: machine, mode: .input)
        )
        machine.states += [machine.states[0]]
        let signal2 = PortSignal(name: .currentStateIn(for: machine), machine: machine, mode: .input)
        XCTAssertEqual(
            signal2?.type,
            .signal(type: .ranged(type: .stdLogicVector(size: .downto(
                upper: .literal(value: .integer(value: 1)), lower: .literal(value: .integer(value: 0))
            ))))
        )
        XCTAssertEqual(
            signal2, PortSignal(name: .currentStateIn(for: machine), bitsRequired: 2, mode: .input)
        )
        machine.states = []
        XCTAssertNil(PortSignal(currentStateInFor: machine))
        XCTAssertNil(PortSignal(name: .currentStateIn(for: machine), machine: machine, mode: .input))
    }

    /// Test remaining machine signals.
    func testStateSignals() {
        XCTAssertEqual(
            PortSignal(currentStateOutFor: machine),
            PortSignal(name: .currentStateOut(for: machine), bitsRequired: 1, mode: .output)
        )
        XCTAssertEqual(PortSignal.reset, PortSignal(type: .stdLogic, name: .reset, mode: .input))
        XCTAssertEqual(
            PortSignal.setInternalSignals,
            PortSignal(type: .stdLogic, name: .setInternalSignals, mode: .input)
        )
        XCTAssertEqual(
            PortSignal(internalStateInFor: machine),
            PortSignal(name: .internalStateIn(for: machine), bitsRequired: 3, mode: .input)
        )
        XCTAssertEqual(
            PortSignal(internalStateOutFor: machine),
            PortSignal(name: .internalStateOut(for: machine), bitsRequired: 3, mode: .output)
        )
        XCTAssertEqual(
            PortSignal(previousRingletInFor: machine),
            PortSignal(name: .previousRingletIn(for: machine), bitsRequired: 1, mode: .input)
        )
        XCTAssertEqual(
            PortSignal(previousRingletOutFor: machine),
            PortSignal(name: .previousRingletOut(for: machine), bitsRequired: 1, mode: .output)
        )
        XCTAssertEqual(
            PortSignal(targetStateInFor: machine),
            PortSignal(name: .targetStateIn(for: machine), bitsRequired: 1, mode: .input)
        )
        XCTAssertEqual(
            PortSignal(targetStateOutFor: machine),
            PortSignal(name: .targetStateOut(for: machine), bitsRequired: 1, mode: .output)
        )
    }

    /// Test that init(signal:,in:,mode:) works correctly for signal typed `LocalSignal`s.
    func testLocalSignalInit() {
        let signal = LocalSignal(type: .stdLogic, name: .x)
        let portSignal = PortSignal(signal: signal, in: machine, mode: .input)
        guard let expectedName = VariableName(rawValue: "M_x") else {
            XCTFail("Failed to create expected name")
            return
        }
        let expected = PortSignal(type: .stdLogic, name: expectedName, mode: .input)
        XCTAssertEqual(portSignal, expected)
    }

    /// Test that init(signal:,in:,mode:) returns nil for alias typed `LocalSignal`s.
    func testLocalSignalInitReturnsNilForAlias() {
        let signal = LocalSignal(type: .alias(name: .y), name: .x)
        XCTAssertNil(PortSignal(signal: signal, in: machine, mode: .input))
    }

}
