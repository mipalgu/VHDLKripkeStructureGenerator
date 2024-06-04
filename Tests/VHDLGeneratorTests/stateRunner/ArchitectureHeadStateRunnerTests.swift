// ArchitectureHeadStateRunnerTests.swift
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

/// Test class for `ArchitectureHead` state runner extensions.
final class ArchitectureHeadStateRunnerTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine, name: .M)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The raw VHDL for the initial state runner architecture head of `machine`.
    var raw: String {
        """
        type Initial_ReadSnapshots_t is array (0 to 8) of ReadSnapshot_t;
        type Initial_WriteSnapshots_t is array (0 to 8) of WriteSnapshot_t;
        type Initial_Targets_t is array (0 to 8) of std_logic_vector(0 downto 0);
        type Initial_Finished_t is array (0 to 8) of boolean;
        type Initial_Ringlets_Working_t is array (0 to 8) of Initial_Ringlet_t;
        type Initial_Pending_States_t is array (0 to 8) of std_logic_vector(5 downto 0);
        signal current_y2: std_logic;
        signal current_M_y: std_logic;
        signal current_M_STATE_Initial_initialX: std_logic;
        signal current_executeOnEntry: boolean;
        signal hasStarted: boolean;
        signal reset: std_logic := '0';
        signal previousRinglet: std_logic_vector(0 downto 0);
        signal readSnapshots: Initial_ReadSnapshots_t;
        signal writeSnapshots: Initial_WriteSnapshots_t;
        signal targets: Initial_Targets_t;
        signal finished: Initial_Finished_t;
        signal workingRinglets: Initial_Ringlets_Working_t;
        signal pendingStates: Initial_Pending_States_t;
        signal internalState: std_logic_vector(3 downto 0) := "0000";
        constant Initial: std_logic_vector(3 downto 0) := "0000";
        constant WaitToStart: std_logic_vector(3 downto 0) := "0001";
        constant StartRunners: std_logic_vector(3 downto 0) := "0010";
        constant WaitForRunners: std_logic_vector(3 downto 0) := "0011";
        constant WaitForFinish: std_logic_vector(3 downto 0) := "0100";
        component MRingletRunner is
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
        end component;
        component InitialKripkeGenerator is
            port(
                clk: in std_logic;
                readSnapshot: in ReadSnapshot_t;
                writeSnapshot: in WriteSnapshot_t;
                ringlet: out Initial_Ringlet_t;
                pendingState: out std_logic_vector(5 downto 0)
            );
        end component;
        component InitialRingletExpander is
            port(
                ringlet: in Initial_Ringlet_t;
                vector: out std_logic_vector(0 to 17)
            );
        end component;
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
        machine.states[0].externalVariables = [.x, .y2]
    }

    /// Test architecture head.
    func testArchitectureHead() {
        let architectureHead = ArchitectureHead(stateRunnerFor: machine.states[0], in: representation)
        // XCTAssertEqual(architectureHead?.rawValue, raw)
    }

}
