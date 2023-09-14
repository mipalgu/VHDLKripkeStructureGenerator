// VHDLFIleRingletRunnerTests.swift
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

/// Test class for `VHDLFile` ringlet runner extensions.
final class VHDLFIleRingletRunnerTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The machine signal definition.
    let machineSignal = "signal machine: TotalSnapshot_t := (x => '0', M_x => '0', y2 => '0', M_y2 => '0'," +
        " M_y2In => '0', M_y => '0', M_yIn => '0', M_STATE_Initial_initialX => '0', " +
        "M_STATE_Initial_initialXIn => '0', currentStateIn => (others => '0'), currentStateOut => " +
        "(others => '0'), previousRingletIn => (others => '0'), previousRingletOut => (others => '0'), " +
        "internalStateIn => ReadSnapshot, internalStateOut => ReadSnapshot, targetStateIn => " +
        "(others => '0'), targetStateOut => (others => '0'), reset => '0', goalInternalState => " +
        "WriteSnapshot, finished => true, executeOnEntry => true, observed => false);"

    /// The raw VHDL for the ringlet runner architecture head of `machine`.
    var head: String {
        """
        constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
        constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";
        \(machineSignal)
        signal tracker: std_logic_vector(1 downto 0) := "00";
        constant WaitForStart: std_logic_vector(1 downto 0) := "00";
        constant Executing: std_logic_vector(1 downto 0) := "01";
        constant WaitForMachineStart: std_logic_vector(1 downto 0) := "10";
        constant WaitForFinish: std_logic_vector(1 downto 0) := "11";
        signal currentState: std_logic_vector(0 downto 0) := "0";
        component MMachineRunner is
            port(
                clk: in std_logic;
                internalStateIn: in std_logic_vector(2 downto 0);
                internalStateOut: out std_logic_vector(2 downto 0);
                currentStateIn: in std_logic_vector(0 downto 0);
                currentStateOut: out std_logic_vector(0 downto 0);
                previousRingletIn: in std_logic_vector(0 downto 0);
                previousRingletOut: out std_logic_vector(0 downto 0);
                targetStateIn: in std_logic_vector(0 downto 0);
                targetStateOut: out std_logic_vector(0 downto 0);
                x: in std_logic;
                y2: out std_logic;
                M_x: out std_logic;
                M_y2: out std_logic;
                M_y2In: in std_logic;
                M_y: out std_logic;
                M_yIn: in std_logic;
                M_STATE_Initial_initialX: out std_logic;
                M_STATE_Initial_initialXIn: in std_logic;
                reset: in std_logic;
                goalInternalState: in std_logic_vector(2 downto 0);
                finished: out boolean := true
            );
        end component;
        """
    }

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

    /// The raw body ringlet runner implementation.
    var body: String {
        """
        \(component)
        \(process)
        """
    }

    /// The raw VHDL entity for the ringlet runner of `machine`.
    let entity = """
    entity MRingletRunner is
        port(
            clk: in std_logic;
            reset: in std_logic := '0';
            state: in std_logic_vector(0 downto 0) := "0";
            x: in std_logic;
            y2: in std_logic;
            M_y: in std_logic;
            M_STATE_Initial_initialX: in std_logic;
            previousRinglet: in std_logic_vector(0 downto 0) := "Z";
            readSnapshotState: out ReadSnapshot_t;
            writeSnapshotState: out WriteSnapshot_t;
            nextState: out std_logic_vector(0 downto 0);
            finished: out boolean := true
        );
    end MRingletRunner;
    """

    /// The includes for the ringlet runner.
    let includes = """
    library IEEE;
    use IEEE.std_logic_1164.all;
    use work.MTypes.all;
    """

    /// The ringlet runner code.
    var raw: String {
        """
        \(includes)

        \(entity)

        architecture Behavioral of MRingletRunner is
        \(head.indent(amount: 1))
        begin
        \(body.indent(amount: 1))
        end Behavioral;

        """
    }

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

    /// Test that the vhdl file creates the ringlet runner correctly.
    func testRingletRunner() {
        let result = VHDLFile(ringletRunnerFor: representation)
        XCTAssertEqual(result?.rawValue, raw)
    }

}
