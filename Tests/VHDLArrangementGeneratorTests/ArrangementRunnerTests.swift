// ArrangementRunnerTests.swift
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

import TestUtils
@testable import VHDLArrangementGenerator
import VHDLMachines
import VHDLParsing
import XCTest

final class ArrangementRunnerTests: XCTestCase {

    func testRawValue() {
        guard let result = VHDLFile(
            arrangementRunerFor: Arrangement.pingPongRepresentation,
            machines: [.pingMachine: MachineRepresentation(machine: .pingMachine, name: .pingMachine)!]
        ) else {
            XCTFail("Failed to create VHDLFile.")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.math_real.all;
        use IEEE.std_logic_1164.all;
        use work.PingMachineTypes.all;

        entity PingPongArrangementRunner is
            port(
                clk: in std_logic;
                ready: in std_logic;
                PingPong_READ_ping: in std_logic;
                PingPong_READ_pong: in std_logic;
                PingPong_WRITE_ping: out std_logic;
                PingPong_WRITE_pong: out std_logic;
                ping_machine_inst_READ_PingMachine_ping: in std_logic;
                ping_machine_inst_READ_executeOnEntry: in boolean;
                ping_machine_inst_READ_state: in std_logic_vector(0 downto 0);
                ping_machine_inst_WRITE_PingMachine_ping: out std_logic;
                ping_machine_inst_WRITE_executeOnEntry: out boolean;
                ping_machine_inst_WRITE_state: out std_logic_vector(0 downto 0);
                busy: out std_logic
            );
        end PingPongArrangementRunner;

        architecture Behavioral of PingPongArrangementRunner is
            type PingPongInternalState_t is (Initial, WaitToStart, WaitForMachineStart, WaitForFinish, SetRingletValue);
            signal internalState: PingPongInternalState_t := Initial;
            signal ping_machine_instWriteSnapshot: work.PingMachineTypes.WriteSnapshot_t;
            signal ping_machine_instPreviousRinglet: std_logic_vector(0 downto 0);
            signal ping_machine_instNextState: std_logic_vector(0 downto 0);
            signal reset: std_logic;
            signal finished: boolean;
            component PingMachineRingletRunner is
                port(
                    clk: in std_logic;
                    reset: in std_logic := '0';
                    state: in std_logic_vector(0 downto 0) := "0";
                    ping: in std_logic;
                    pong: in std_logic;
                    previousRinglet: in std_logic_vector(0 downto 0) := "Z";
                    readSnapshotState: out ReadSnapshot_t;
                    writeSnapshotState: out WriteSnapshot_t;
                    nextState: out std_logic_vector(0 downto 0);
                    finished: out boolean := true
                );
            end component;
        begin
            ping_machine_inst: component PingMachineRingletRunner port map (
                clk => clk,
                reset => reset,
                state => ping_machine_inst_READ_state,
                ping => PingPong_READ_ping,
                pong => PingPong_READ_pong,
                previousRinglet => ping_machine_instPreviousRinglet,
                readSnapshotState => open,
                writeSnapshotState => ping_machine_instWriteSnapshot,
                nextState => ping_machine_instNextState,
                finished => finished
            );
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            reset <= '1';
                            busy <= '0';
                            internalState <= WaitToStart;
                        when WaitToStart =>
                            if (ready = '1' and finished) then
                                reset <= '0';
                                busy <= '1';
                                internalState <= WaitForMachineStart;
                                if (ping_machine_inst_READ_executeOnEntry) then
                                    ping_machine_instPreviousRinglet <= ping_machine_inst_READ_state xor "1";
                                else
                                    ping_machine_instPreviousRinglet <= ping_machine_inst_READ_state;
                                end if;
                            else
                                reset <= '1';
                                busy <= '0';
                                internalState <= WaitToStart;
                            end if;
                        when WaitForMachineStart =>
                            reset <= '0';
                            busy <= '1';
                            internalState <= WaitForFinish;
                        when WaitForFinish =>
                            if (finished) then
                                internalState <= SetRingletValue;
                            else
                                internalState <= WaitForFinish;
                            end if;
                            reset <= '0';
                            busy <= '1';
                        when SetRingletValue =>
                            reset <= '0';
                            busy <= '0';
                            internalState <= WaitToStart;
                            ping_machine_inst_WRITE_PingMachine_ping <= ping_machine_instWriteSnapshot.PingMachine_ping;
                            ping_machine_inst_WRITE_executeOnEntry <= ping_machine_instWriteSnapshot.executeOnEntry;
                            ping_machine_inst_WRITE_state <= ping_machine_instNextState;
                        when others =>
                            null;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

}
