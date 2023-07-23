// PortBlockTests.swift
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

/// Test class for `PortBlock` extensions.
final class PortBlockTests: XCTestCase {

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
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
    }

    // swiftlint:disable function_body_length

    /// Test the `PortBlock` `init(verifiable:)` initialiser.
    func testVerifiableInit() {
        guard
            let block = PortBlock(verifiable: representation),
            let suspendedName = VariableName(rawValue: "suspended"),
            let commandName = VariableName(rawValue: "command"),
            let xName = VariableName(rawValue: "EXTERNAL_x"),
            let xSnapshotName = VariableName(rawValue: "M_x"),
            let yName = VariableName(rawValue: "M_y"),
            let yNameIn = VariableName(rawValue: "M_yIn"),
            let y2Name = VariableName(rawValue: "EXTERNAL_y2"),
            let y2Snapshot = VariableName(rawValue: "M_y2"),
            let y2SnapshotIn = VariableName(rawValue: "M_y2In"),
            let initialXIn = VariableName(rawValue: "M_STATE_Initial_initialXIn"),
            let initialXOut = VariableName(rawValue: "M_STATE_Initial_initialX"),
            let currentStateIn = PortSignal(currentStateInFor: machine),
            let currentStateOut = PortSignal(currentStateOutFor: machine),
            let previousRingletIn = PortSignal(previousRingletInFor: machine),
            let previousRingletOut = PortSignal(previousRingletOutFor: machine),
            let internalStateIn = PortSignal(internalStateInFor: machine),
            let internalStateOut = PortSignal(internalStateOutFor: machine),
            let targetStateIn = PortSignal(targetStateInFor: machine),
            let targetStateOut = PortSignal(targetStateOutFor: machine),
            let expected = PortBlock(signals: [
                PortSignal(clock: machine.clocks[0]),
                PortSignal(type: .stdLogic, name: xName, mode: .input),
                PortSignal(type: .stdLogic, name: y2Name, mode: .output),
                PortSignal(type: .stdLogic, name: suspendedName, mode: .output),
                PortSignal(
                    type: .ranged(type: .stdLogicVector(size: .downto(
                        upper: .literal(value: .integer(value: 1)), lower: .literal(value: .integer(value: 0))
                    ))),
                    name: commandName,
                    mode: .input
                ),
                PortSignal(type: .stdLogic, name: xSnapshotName, mode: .output),
                PortSignal(type: .stdLogic, name: y2SnapshotIn, mode: .input),
                PortSignal(type: .stdLogic, name: y2Snapshot, mode: .output),
                PortSignal(type: .stdLogic, name: yName, mode: .output),
                PortSignal(type: .stdLogic, name: yNameIn, mode: .input),
                PortSignal(type: .stdLogic, name: initialXOut, mode: .output),
                PortSignal(type: .stdLogic, name: initialXIn, mode: .input),
                currentStateIn,
                currentStateOut,
                previousRingletIn,
                previousRingletOut,
                internalStateIn,
                internalStateOut,
                targetStateIn,
                targetStateOut,
                .setInternalSignals,
                .reset
            ])
        else {
            XCTFail("Failed to create expected block.")
            return
        }
        // block.rawValue.components(separatedBy: .newlines).forEach { print($0) }
        XCTAssertEqual(block, expected)
    }

    // swiftlint:enable function_body_length

    /// Test that `PortBlock.init(verifiable:)` returns `nil` when the machine has a type-aliased signal.
    func testVerifiableInitReturnsNilForAliasType() {
        machine.machineSignals = [LocalSignal(type: .alias(name: .x), name: .y)]
        XCTAssertNil(PortBlock(verifiable: representation))
    }

}
