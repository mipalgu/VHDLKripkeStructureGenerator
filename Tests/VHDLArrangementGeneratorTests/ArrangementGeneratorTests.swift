// ArrangementGeneratorTests.swift
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

final class ArrangementGeneratorTests: XCTestCase {

    // swiftlint:disable line_length
    // swiftlint:disable function_body_length

    /// Test generator creation.
    func testRawValue() {
        guard let result = VHDLFile(
            generatorFor: Arrangement.pingPongRepresentation,
            machines: [.pingMachine: MachineRepresentation(machine: .pingMachine, name: .pingMachine)!]
        ) else {
            XCTFail("Failed to create VHDLFile.")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use work.PrimitiveTypes.all;
        use work.PingMachineTypes.all;

        entity PingPongGenerator is
            port(
                clk: in std_logic;
                address: in std_logic_vector(9 downto 0);
                read: in std_logic;
                ready: in std_logic;
                data: out std_logic_vector(31 downto 0);
                overflow: std_logic;
                finished: out std_logic
            );
        end PingPongGenerator;

        architecture Behavioral of PingPongGenerator is
            type MachineIndex_t is integer range 0 to 8;
            signal machineIndex: MachineIndex_t;
            signal ready: std_logic;
            signal PingPong_READ_ping: array (0 to 2) of std_logic;
            signal PingPong_READ_pong: array (0 to 2) of std_logic;
            signal PingPong_WRITE_ping: array (0 to 8) of std_logic;
            signal PingPong_WRITE_pong: array (0 to 8) of std_logic;
            signal ping_machine_inst_READ_PingMachine_ping: array (0 to 8) of std_logic;
            signal ping_machine_inst_READ_executeOnEntry: array (0 to 8) of boolean;
            signal ping_machine_inst_READ_state: array (0 to 8) of std_logic_vector(0 downto 0);
            signal ping_machine_inst_WRITE_PingMachine_ping: array (0 to 8) of std_logic;
            signal ping_machine_inst_WRITE_executeOnEntry: array (0 to 8) of boolean;
            signal ping_machine_inst_WRITE_state: array (0 to 8) of std_logic_vector(0 downto 0);
            signal busy: std_logic;
            signal snapshot: array (0 to 8) of std_logic_vector(15 downto 0);
            signal snapshotEnable: array (0 to 8) of std_logic;
            signal snapshotIndex: MachineIndex_t;
            signal cacheReady: std_logic;
            signal cacheWe: std_logic;
            signal cacheData: std_logic_vector(15 downto 0);
            signal cacheAddress: std_logic_vector(9 downto 0);
            signal cacheBusy: std_logic;
            signal cacheLastAddress: std_logic_vector(9 downto 0);
            signal cacheValue: std_logic_vector(15 downto 0);
            signal cacheValueEn: std_logic;
            signal generationFinished: std_logic;
            type PingPongGenerator_InternalState_t is (Initial, StartExecution, WaitForStart, WaitForFinish, ResetSnapshotIndex, RemoveDuplicates, SetCacheToEndAddress, OverflowDetected, WaitForWriteStart, WaitForWriteEnd, ResetTargetStateIndex, StartCacheRead, SetNextAddress, WaitForReadStart, WaitForReadEnd, CheckForDuplicate);
            signal internalState: PingPongGenerator_InternalState_t := Initial;
            component PingPongArrangementRunner is
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
            end component;
            component PingPongSnapshotEncoder is
                port(
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
                    enable: in std_logic;
                    data: out std_logic_vector(15 downto 0)
                );
            end component;
            component PingPongCache is
                port(
                    clk: in std_logic;
                    address: in std_logic_vector(9 downto 0);
                    data: in std_logic_vector(15 downto 0);
                    we: in std_logic;
                    ready: in std_logic;
                    busy: out std_logic;
                    value: out std_logic_vector(15 downto 0);
                    value_en: out std_logic;
                    lastAddress: out std_logic_vector(9 downto 0)
                );
            end PingPongCache;
        begin
            PingPongRunner_inst0: for i0 in 0 to 2 generate
                PingPongRunner_inst1: for i1 in 0 to 2 generate
                    PingPongRunner_inst: PingPongArrangementRunner port map (
                        clk => clk,
                        ready => ready,
                        PingPong_READ_ping => stdLogicTypes(i0),
                        PingPong_READ_pong => stdLogicTypes(i1),
                        PingPong_WRITE_ping => PingPong_WRITE_ping(i0 + 3 * i1),
                        PingPong_WRITE_pong => PingPong_WRITE_pong(i0 + 3 * i1),
                        ping_machine_inst_READ_PingMachine_ping => ping_machine_inst_READ_PingMachine_ping(i0 + 3 * i1),
                        ping_machine_inst_READ_executeOnEntry => ping_machine_inst_READ_executeOnEntry(i0 + 3 * i1),
                        ping_machine_inst_READ_state => ping_machine_inst_READ_state(i0 + 3 * i1),
                        ping_machine_inst_WRITE_PingMachine_ping => ping_machine_inst_WRITE_PingMachine_ping(i0 + 3 * i1),
                        ping_machine_inst_WRITE_executeOnEntry => ping_machine_inst_WRITE_executeOnEntry(i0 + 3 * i1),
                        ping_machine_inst_WRITE_state => ping_machine_inst_WRITE_state(i0 + 3 * i1),
                        busy => busy
                    );
                    PingPongSnapshotEncoder_inst: PingPongSnapshotEncoder port map (
                        PingPong_READ_ping => stdLogicTypes(i0),
                        PingPong_READ_pong => stdLogicTypes(i1),
                        PingPong_WRITE_ping => PingPong_WRITE_ping(i0 + 3 * i1),
                        PingPong_WRITE_pong => PingPong_WRITE_pong(i0 + 3 * i1),
                        ping_machine_inst_READ_PingMachine_ping => ping_machine_inst_READ_PingMachine_ping(i0 + 3 * i1),
                        ping_machine_inst_READ_executeOnEntry => ping_machine_inst_READ_executeOnEntry(i0 + 3 * i1),
                        ping_machine_inst_READ_state => ping_machine_inst_READ_state(i0 + 3 * i1),
                        ping_machine_inst_WRITE_PingMachine_ping => ping_machine_inst_WRITE_PingMachine_ping(i0 + 3 * i1),
                        ping_machine_inst_WRITE_executeOnEntry => ping_machine_inst_WRITE_executeOnEntry(i0 + 3 * i1),
                        ping_machine_inst_WRITE_state => ping_machine_inst_WRITE_state(i0 + 3 * i1),
                        enable => snapshotEnable(i0 + 3 * i1),
                        data => snapshot(i0 + 3 * i1)
                    );
                end generate PingPongRunner_inst1;
            end generate PingPongRunner_inst0;
            cache_inst: PingPongCache port map (
                clk => clk,
                address => address,
                data => cacheData,
                we => '0',
                ready => ready,
                busy => busy,
                value => cacheValue,
                value_en => cacheValueEn,
                lastAddress => stdLogicVectorTypes(machineIndex)
            );
            finished <= generationFinished;
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            ready <= '0';
                            machineIndex <= 0;
                            ping_machine_inst_READ_PingMachine_ping <= '0';
                            ping_machine_inst_READ_executeOnEntry <= true;
                            ping_machine_inst_READ_state <= work.PingMachineTypes.STATE_Initial;
                            snapshotEnable <= (others => '0');
                            generationFinished <= '0';
                            cacheAddress <= (others => '0');
                            cacheWe <= '0';
                            cacheReady <= '0';
                            cacheData <= (others => '0');
                            overflow <= '0';
                            if (busy = '0') then
                                internalState <= StartExecution;
                            else
                                internalState <= Initial;
                            end if;
                        when StartExecution =>
                            ready <= '1';
                            snapshotEnable <= (others => '0');
                            internalState <= WaitForStart;
                        when WaitForStart =>
                            if (busy = '1') then
                                ready <= '0';
                                internalState <= WaitForFinish;
                            else
                                ready <= '1';
                                internalState <= WaitForStart;
                            end if;
                            snapshotEnable <= (others => '0');
                        when WaitForFinish =>
                            if (busy = '0') then
                                snapshotEnable <= (others => '1');
                                internalState <= ResetSnapshotIndex;
                            else
                                snapshotEnable <= (others => '0');
                                internalState <= WaitForFinish;
                            end if;
                            ready <= '0';
                        when ResetSnapshotIndex =>
                            snapshotIndex <= 0;
                            machineIndex <= 1;
                            internalState <= RemoveDuplicates;
                        when RemoveDuplicates =>
                            if (snapshotIndex = machineIndex) then
                                snapshotIndex <= 0;
                                if (machineIndex = 8) then
                                    internalState <= SetCacheToEndAddress;
                                    machineIndex <= 0;
                                else
                                    machineIndex <= machineIndex + 1;
                                    internalState <= RemoveDuplicates;
                                end if;
                            elsif (snapshot(snapshotIndex) = snapshot(machineIndex)) then
                                snapshotEnable(machineIndex) <= '0';
                                snapshotIndex <= 0;
                                if (machineIndex = 8) then
                                    internalState <= SetCacheToEndAddress;
                                    machineIndex <= 0;
                                else
                                    machineIndex <= machineIndex + 1;
                                    internalState <= RemoveDuplicates;
                                end if;
                            else
                                snapshotIndex <= snapshotIndex + 1;
                                internalState <= RemoveDuplicates;
                            end if;
                        when SetCacheToEndAddress =>
                            if (cacheLastAddress = (others => '1')) then
                                internalState <= OverflowDetected;
                            elsif (cacheBusy = '0') then
                                cacheAddress <= std_logic_vector(unsigned(cacheLastAddress) + 1);
                                cacheWe <= '1';
                                cacheReady <= '1';
                                cacheData <= snapshot(machineIndex);
                                internalState <= WaitForWriteStart;
                            else
                                internalState <= SetCacheToEndAddress;
                            end if;
                        when WaitForWriteStart =>
                            if (cacheBusy = '1') then
                                cacheReady <= '0';
                                cacheWe <= '0';
                                internalState <= WaitForWriteEnd;
                            else
                                cacheWe <= '1';
                                cacheReady <= '1';
                                cacheData <= snapshot(machineIndex);
                                internalState <= WaitForWriteStart;
                            end if;
                        when WaitForWriteEnd =>
                            if (cacheBusy = '0') then
                                if (machineIndex = 8) then
                                    machineIndex <= 0;
                                    internalState <= ResetTargetStateIndex;
                                else
                                    machineIndex <= machineIndex + 1;
                                    internalState <= SetCacheToEndAddress;
                                end if;
                            else
                                cacheReady <= '0';
                                cacheWe <= '0';
                                internalState <= WaitForWriteEnd;
                            end if;
                        when ResetTargetStateIndex =>
                            cacheAddress <= (others => '0');
                            cacheReady <= '0';
                            cacheWe <= '0';
                            internalState <= StartCacheRead;
                        when StartCacheRead =>
                            if (cacheBusy = '0') then
                                cacheReady <= '1';
                                cacheWe <= '0';
                                internalState <= WaitForReadStart;
                            else
                                cacheReady <= '0';
                                cacheWe <= '0';
                                internalState <= StartCacheRead;
                            end if;
                        when WaitForReadStart =>
                            if (cacheBusy = '1') then
                                cacheReady <= '0';
                                cacheWe <= '0';
                                internalState <= WaitForReadEnd;
                            else
                                cacheReady <= '1';
                                cacheWe <= '0';
                                internalState <= WaitForReadStart;
                            end if;
                        when WaitForReadEnd =>
                            if (cacheBusy = '0') then
                                internalState <= CheckForDuplicate;
                            else
                                internalState <= WaitForReadEnd;
                            end if;
                            cacheReady <= '0';
                            cacheWe <= '0';
                        when CheckForDuplicate =>
                            if (cacheValue = snapshot(machineIndex)) then
                                snapshotEnable(machineIndex) <= '0';
                                if (machineIndex = 8) then
                                    machineIndex <= 0;
                                else
                                    machineIndex <= machineIndex + 1;
                                    internalState <= ResetTargetStateIndex;
                                end if;
                            end if;
                        when OverflowDetected =>
                            overflow <= '1';
                            generationFinished <= '0';
                        when others =>
                            null;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

    // swiftlint:enable function_body_length
    // swiftlint:enable line_length

}
