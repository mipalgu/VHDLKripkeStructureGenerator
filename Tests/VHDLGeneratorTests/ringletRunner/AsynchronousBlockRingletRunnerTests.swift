// AsynchronousBlockRingletRunnerTests.swift
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

@testable import VHDLGenerator
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for `AsynchronousBlock` ringlet runner extensions.
final class AsynchronousBlockRingletRunnerTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine, name: .M)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The WaitForMachineStart case.
    let waitForMachineStart = """
    when WaitForMachineStart =>
        machine.reset <= '1';
        tracker <= Executing;
    """

    /// The WaitForFinish case.
    let waitForFinish = """
    when WaitForFinish =>
        if (reset = '0') then
            machine.reset <= '0';
            tracker <= WaitForStart;
        end if;
    """

    /// The assignment of readSnapshotState
    let readSnapshotState = "readSnapshotState <= (x => x, state => state, M_y2 => y2, M_y => M_y," +
        " M_STATE_Initial_initialX => M_STATE_Initial_initialX, executeOnEntry => previousRinglet /= state);"

    /// The WaitForStart case.
    var waitForStart: String {
        """
        when WaitForStart =>
            if (reset = '1') then
                tracker <= WaitForMachineStart;
                machine.reset <= '1';
                \(readSnapshotState)
                finished <= false;
            else
                machine.x <= x;
                machine.currentStateIn <= state;
                machine.internalStateIn <= ReadSnapshot;
                machine.targetStateIn <= state;
                machine.reset <= '0';
                machine.goalInternalState <= WriteSnapshot;
                machine.previousRingletIn <= previousRinglet;
                machine.M_y2In <= y2;
                machine.M_yIn <= M_y;
                machine.M_STATE_Initial_initialXIn <= M_STATE_Initial_initialX;
            end if;
            currentState <= state;
        """
    }

    /// The assignment of writeSnapshotState.
    let writeSnapshotState = "writeSnapshotState <= (x => machine.M_x, y2 => machine.M_y2," +
        " M_y => machine.M_y, M_STATE_Initial_initialX => machine.M_STATE_Initial_initialX," +
        " state => currentState, nextState => machine.currentStateOut," +
        " executeOnEntry => machine.currentStateOut /= currentState);"

    /// The executing case.
    var executing: String {
        """
        when Executing =>
            machine.reset <= '1';
            if (machine.finished) then
                \(writeSnapshotState)
                nextState <= machine.currentStateOut;
                finished <= true;
                tracker <= WaitForFinish;
            end if;
        """
    }

    /// The raw VHDL for the ringlet runner process of `machine`.
    var process: String {
        """
        process(clk)
        begin
            if (rising_edge(clk)) then
                case tracker is
        \(waitForStart.indent(amount: 3))
        \(waitForMachineStart.indent(amount: 3))
        \(executing.indent(amount: 3))
        \(waitForFinish.indent(amount: 3))
                    when others =>
                        null;
                end case;
            end if;
        end process;
        """
    }

    /// The component instantiation.
    let component = """
    M_inst: component MMachineRunner port map (
        clk => clk,
        internalStateIn => machine.internalStateIn,
        internalStateOut => machine.internalStateOut,
        currentStateIn => machine.currentStateIn,
        currentStateOut => machine.currentStateOut,
        previousRingletIn => machine.previousRingletIn,
        previousRingletOut => machine.previousRingletOut,
        targetStateIn => machine.targetStateIn,
        targetStateOut => machine.targetStateOut,
        x => machine.x,
        y2 => machine.y2,
        M_x => machine.M_x,
        M_y2 => machine.M_y2,
        M_y2In => machine.M_y2In,
        M_y => machine.M_y,
        M_yIn => machine.M_yIn,
        M_STATE_Initial_initialX => machine.M_STATE_Initial_initialX,
        M_STATE_Initial_initialXIn => machine.M_STATE_Initial_initialXIn,
        reset => machine.reset,
        goalInternalState => machine.goalInternalState,
        finished => machine.finished
    );
    """

    /// The raw ringlet runner implementation.
    var raw: String {
        """
        \(component)
        \(process)
        """
    }

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initialSuspensible
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
    }

    /// Test the process block is correct.
    func testProcess() {
        let result = ProcessBlock(ringletRunnerFor: representation)
        // XCTAssertEqual(result?.rawValue, process)
    }

    /// Test that the ringlet runner creates the correct code.
    func testRingletRunnerInit() {
        let result = AsynchronousBlock(ringletRunnerFor: representation)
        // XCTAssertEqual(result?.rawValue, raw)
    }

}
