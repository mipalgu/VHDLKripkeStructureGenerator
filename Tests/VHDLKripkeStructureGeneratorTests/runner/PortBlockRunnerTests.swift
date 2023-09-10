// PortBlockRunnerTests.swift
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
@testable import VHDLMachines
@testable import VHDLParsing
import XCTest

/// Test class for `PortBlock` machine runner extension.
final class PortBlockRunnerTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use as test data.
    var machine: Machine!

    /// The representation of the machine.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The tracker signals.
    let trackersRaw = [
        "clk: in std_logic",
        "internalStateIn: in std_logic_vector(2 downto 0)",
        "internalStateOut: out std_logic_vector(2 downto 0)",
        "currentStateIn: in std_logic_vector(0 downto 0)",
        "currentStateOut: out std_logic_vector(0 downto 0)",
        "previousRingletIn: in std_logic_vector(0 downto 0)",
        "previousRingletOut: out std_logic_vector(0 downto 0)",
        "targetStateIn: in std_logic_vector(0 downto 0)",
        "targetStateOut: out std_logic_vector(0 downto 0)"
    ]

    /// The control signals.
    let controlSignals = [
        "reset: in std_logic",
        "goalInternalState: in std_logic_vector(2 downto 0)",
        "finished: out boolean := true"
    ]

    /// Initialises the machine before each test.
    override func setUp() {
        machine = Machine.initial(path: URL(fileURLWithPath: "/path/to/M.machine", isDirectory: true))
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
    }

    /// Test that the new String init creates the label correctly.
    func testStringInit() {
        XCTAssertEqual(String(labelFor: machine.name), "m")
        guard let name = VariableName(rawValue: "machine") else {
            XCTFail("Failed to create name")
            return
        }
        XCTAssertEqual(String(labelFor: name), "machine")
    }

    /// Test property init returns nil for invalid parameters
    func testPropertyInitReturnsNil() {
        XCTAssertNil(PortBlock(
            numberOfStates: -1, externals: [], snapshots: [], machineVariables: [], stateSignals: []
        ))
    }

    /// Test the init works correctly.
    func testInit() {
        let raw = [
            "x: in std_logic",
            "y2: out std_logic",
            "M_x: out std_logic",
            "M_y2: out std_logic",
            "M_y2In: in std_logic",
            "M_y: out std_logic",
            "M_yIn: in std_logic",
            "M_STATE_Initial_initialX: out std_logic",
            "M_STATE_Initial_initialXIn: in std_logic"
        ]
        let trackers = self.trackersRaw.compactMap(PortSignal.init(rawValue:))
        let controls = self.controlSignals.compactMap(PortSignal.init(rawValue:))
        let variables = raw.compactMap(PortSignal.init(rawValue:))
        guard
            trackers.count == trackersRaw.count,
            controls.count == controlSignals.count,
            variables.count == raw.count
        else {
            XCTFail("Failed to create signals")
            return
        }
        let expected = PortBlock(signals: trackers + variables + controls)
        let result = PortBlock(runnerFor: representation)
        XCTAssertEqual(result, expected, result?.rawValue ?? "")
    }

    /// Test that the property init works correctly.
    func testPropertyInit() {
        let snapshotsRaw = [
            "M_x: out std_logic",
            "M_y2: out std_logic",
            "M_y2In: in std_logic"
        ]
        let machinesRaw = ["M_y: out std_logic", "M_yIn: in std_logic"]
        let statesRaw = [
            "M_STATE_Initial_initialX: out std_logic", "M_STATE_Initial_initialXIn: in std_logic"
        ]
        let trackers = self.trackersRaw.compactMap(PortSignal.init(rawValue:))
        let controls = self.controlSignals.compactMap(PortSignal.init(rawValue:))
        let snapshots = snapshotsRaw.compactMap(PortSignal.init(rawValue:))
        let machines = machinesRaw.compactMap(PortSignal.init(rawValue:))
        let states = statesRaw.compactMap(PortSignal.init(rawValue:))
        guard
            trackers.count == trackersRaw.count,
            controls.count == controlSignals.count,
            snapshots.count == snapshotsRaw.count,
            machines.count == machinesRaw.count,
            states.count == statesRaw.count
        else {
            XCTFail("Failed to create signals")
            return
        }
        let expected = PortBlock(
            signals: trackers + machine.externalSignals + snapshots + machines + states + controls
        )
        let result = PortBlock(
            numberOfStates: 2,
            externals: machine.externalSignals,
            snapshots: snapshots,
            machineVariables: machines,
            stateSignals: states
        )
        XCTAssertEqual(expected, result)
    }

}
