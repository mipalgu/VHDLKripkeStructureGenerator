// StateGeneratorTests.swift
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
@testable import VHDLGenerator
import VHDLMachines
import VHDLParsing
import XCTest

// swiftlint:disable file_length
// swiftlint:disable type_body_length

/// Test class for state generator creation.
final class StateGeneratorTests: XCTestCase {

    // swiftlint:disable force_unwrapping

    /// The machine to use as test data.
    let representation = MachineRepresentation(machine: Machine.pingMachine, name: .pingMachine)!

    // swiftlint:enable force_unwrapping

    /// The `initial` state.
    var state: State {
        representation.machine.states[0]
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable line_length

    /// Test concurrent state generator.
    func testConcurrent() {
        guard let result = VHDLFile(concurrentStateGeneratorFor: state, in: representation) else {
            XCTFail("Result is nil!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use work.PingMachineTypes.all;
        use work.PrimitiveTypes.all;

        entity InitialGenerator is
            port(
                clk: in std_logic;
                ping: in std_logic;
                executeOnEntry: in boolean;
                address: in std_logic_vector(31 downto 0);
                ready: in std_logic;
                read: in std_logic;
                busy: out std_logic;
                targetStates: out TargetStates_t;
                value: out std_logic_vector(31 downto 0);
                lastAddress: out std_logic_vector(31 downto 0)
            );
        end InitialGenerator;

        architecture Behavioral of InitialGenerator is
            signal startGeneration: std_logic;
            signal startCache: std_logic;
            signal ringlets: Initial_State_Execution_t;
            signal runnerBusy: std_logic;
            signal cacheBusy: std_logic;
            signal cacheRead: boolean;
            signal statesIndex: integer range 0 to 12;
            signal ringletIndex: integer range 0 to 1;
            signal states: TargetStates_t;
            signal hasDuplicate: boolean;
            signal internalState: std_logic_vector(3 downto 0) := x"0";
            constant Initial: std_logic_vector(3 downto 0) := x"0";
            constant CheckForJob: std_logic_vector(3 downto 0) := x"1";
            constant WaitForRunnerToStart: std_logic_vector(3 downto 0) := x"2";
            constant WaitForRunnerToFinish: std_logic_vector(3 downto 0) := x"3";
            constant WaitForCacheToStart: std_logic_vector(3 downto 0) := x"4";
            constant WaitForCacheToEnd: std_logic_vector(3 downto 0) := x"5";
            constant CheckForDuplicates: std_logic_vector(3 downto 0) := x"6";
            constant Error: std_logic_vector(3 downto 0) := x"7";
            constant AddToStates: std_logic_vector(3 downto 0) := x"8";
            signal genRead: boolean;
            signal genReady: std_logic;
            component InitialRingletCache is
                port(
                    clk: in std_logic;
                    newRinglets: in Initial_State_Execution_t;
                    readAddress: in std_logic_vector(31 downto 0);
                    value: out std_logic_vector(31 downto 0);
                    read: in boolean;
                    ready: in std_logic;
                    busy: out std_logic;
                    lastAddress: out std_logic_vector(31 downto 0)
                );
            end component;
            component InitialStateRunner is
                port(
                    clk: in std_logic;
                    ping: in std_logic;
                    executeOnEntry: in boolean;
                    ready: in std_logic;
                    ringlets: out Initial_State_Execution_t;
                    busy: out std_logic := '0';
                    working_ping: out std_logic;
                    working_executeOnEntry: out boolean
                );
            end component;
        begin
            runner_inst: component InitialStateRunner port map (
                clk => clk,
                ping => ping,
                executeOnEntry => executeOnEntry,
                ready => startGeneration,
                ringlets => ringlets,
                busy => runnerBusy
            );
            cache_inst: component InitialRingletCache port map (
                clk => clk,
                newRinglets => ringlets,
                readAddress => address,
                value => value,
                read => genRead,
                ready => genReady,
                busy => cacheBusy,
                lastAddress => lastAddress
            );
            genRead <= true when read = '1' and internalState = CheckForJob else cacheRead;
            genReady <= '1' when ready = '1' and internalState = CheckForJob else startCache;
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            busy <= '0';
                            startGeneration <= '0';
                            startCache <= '0';
                            cacheRead <= true;
                            internalState <= CheckForJob;
                            statesIndex <= 0;
                            ringletIndex <= 0;
                            states <= (others => (others => '0'));
                            hasDuplicate <= false;
                        when CheckForJob =>
                            if (ready = '1') then
                                if (read = '1') then
                                    startCache <= '1';
                                    busy <= '0';
                                    startGeneration <= '0';
                                else
                                    busy <= '1';
                                    startGeneration <= '1';
                                    internalState <= WaitForRunnerToStart;
                                end if;
                            else
                                startGeneration <= '0';
                                startCache <= '0';
                                cacheRead <= true;
                                busy <= '0';
                            end if;
                        when WaitForRunnerToStart =>
                            if (runnerBusy = '1') then
                                internalState <= WaitForRunnerToFinish;
                                startGeneration <= '0';
                            end if;
                            busy <= '1';
                            startCache <= '0';
                        when WaitForRunnerToFinish =>
                            if (runnerBusy = '0') then
                                if (cacheBusy = '0') then
                                    internalState <= WaitForCacheToStart;
                                    startCache <= '1';
                                    cacheRead <= false;
                                else
                                    startCache <= '0';
                                    cacheRead <= true;
                                end if;
                            else
                                cacheRead <= true;
                                startCache <= '0';
                            end if;
                            startGeneration <= '0';
                            busy <= '1';
                        when WaitForCacheToStart =>
                            if (cacheBusy = '1') then
                                internalState <= CheckForDuplicates;
                                startCache <= '0';
                                statesIndex <= 0;
                                ringletIndex <= 0;
                                states <= (others => (others => '0'));
                                hasDuplicate <= false;
                            else
                                startCache <= '1';
                            end if;
                            startGeneration <= '0';
                            busy <= '1';
                            cacheRead <= false;
                        when CheckForDuplicates =>
                            if (statesIndex = 12) then
                                internalState <= Error;
                            elsif (ringletIndex = 1) then
                                internalState <= WaitForCacheToEnd;
                            elsif (ringlets(ringletIndex)(7) = '1') then
                                for i in 0 to 10 loop
                                    if (states(i)(0) = '1') then
                                        if (states(i) = encodedToStdLogic(ringlets(ringletIndex)(3 to 4)) & ringlets(ringletIndex)(5) & ringlets(ringletIndex)(6) & '1') then
                                            hasDuplicate <= true;
                                        end if;
                                    end if;
                                end loop;
                                internalState <= AddToStates;
                            else
                                ringletIndex <= ringletIndex + 1;
                            end if;
                            busy <= '1';
                            cacheRead <= false;
                            startGeneration <= '0';
                            startCache <= '0';
                        when AddToStates =>
                            if (not hasDuplicate) then
                                if (ringlets(ringletIndex)(7) = '1') then
                                    states(statesIndex) <= encodedToStdLogic(ringlets(ringletIndex)(3 to 4)) & ringlets(ringletIndex)(5) & ringlets(ringletIndex)(6) & '1';
                                    statesIndex <= statesIndex + 1;
                                end if;
                            end if;
                            busy <= '1';
                            cacheRead <= false;
                            startGeneration <= '0';
                            startCache <= '0';
                            hasDuplicate <= false;
                            ringletIndex <= ringletIndex + 1;
                            internalState <= CheckForDuplicates;
                        when WaitForCacheToEnd =>
                            startCache <= '0';
                            busy <= '1';
                            cacheRead <= false;
                            if (cacheBusy = '0') then
                                internalState <= CheckForJob;
                                targetStates <= states;
                            end if;
                        when others =>
                            null;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

    /// Test the sequential state generator.
    func testSequential() {
        guard let result = VHDLFile(sequentialStateGeneratorFor: state, in: representation) else {
            XCTFail("Result is nil!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;
        use work.PingMachineTypes.all;
        use work.PrimitiveTypes.all;

        entity InitialGenerator is
            port(
                clk: in std_logic;
                ping: in std_logic;
                executeOnEntry: in boolean;
                address: in std_logic_vector(31 downto 0);
                ready: in std_logic;
                read: in std_logic;
                busy: out std_logic;
                targetStatesaddress: out std_logic_vector(3 downto 0);
                targetStatesdata: out std_logic_vector(2 downto 0);
                targetStateswe: out std_logic;
                targetStatesready: out std_logic;
                targetStatesbusy: in std_logic;
                targetStatesvalue: in std_logic_vector(2 downto 0);
                targetStatesvalue_en: in std_logic;
                targetStateslastAddress: in std_logic_vector(3 downto 0);
                targetStatesen: in std_logic;
                value: out std_logic_vector(31 downto 0);
                lastAddress: out std_logic_vector(31 downto 0)
            );
        end InitialGenerator;

        architecture Behavioral of InitialGenerator is
            signal startGeneration: std_logic;
            signal startCache: std_logic;
            signal ringlets: Initial_State_Execution_t;
            signal runnerBusy: std_logic;
            signal cacheBusy: std_logic;
            signal cacheRead: boolean;
            signal statesIndex: unsigned(3 downto 0);
            signal ringletIndex: integer range 0 to 1;
            type InitialGeneratorInternalState_t is (Initial, CheckForJob, WaitForRunnerToStart, WaitForRunnerToFinish, WaitForCacheToStart, WaitForCacheToEnd, CheckForDuplicates, Error, AddToStates, ResetStateIndex, SetNextTargetState, SetNextRinglet, WaitForRead, WaitForReadEnable);
            signal internalState: InitialGeneratorInternalState_t := Initial;
            signal genRead: boolean;
            signal genReady: std_logic;
            component InitialRingletCache is
                port(
                    clk: in std_logic;
                    newRinglets: in Initial_State_Execution_t;
                    readAddress: in std_logic_vector(31 downto 0);
                    value: out std_logic_vector(31 downto 0);
                    read: in boolean;
                    ready: in std_logic;
                    busy: out std_logic;
                    lastAddress: out std_logic_vector(31 downto 0)
                );
            end component;
            component InitialStateRunner is
                port(
                    clk: in std_logic;
                    ping: in std_logic;
                    executeOnEntry: in boolean;
                    ready: in std_logic;
                    ringlets: out Initial_State_Execution_t;
                    busy: out std_logic := '0';
                    working_ping: out std_logic;
                    working_executeOnEntry: out boolean
                );
            end component;
        begin
            runner_inst: component InitialStateRunner port map (
                clk => clk,
                ping => ping,
                executeOnEntry => executeOnEntry,
                ready => startGeneration,
                ringlets => ringlets,
                busy => runnerBusy
            );
            cache_inst: component InitialRingletCache port map (
                clk => clk,
                newRinglets => ringlets,
                readAddress => address,
                value => value,
                read => genRead,
                ready => genReady,
                busy => cacheBusy,
                lastAddress => lastAddress
            );
            genRead <= true when read = '1' and internalState = CheckForJob else cacheRead;
            genReady <= '1' when ready = '1' and internalState = CheckForJob else startCache;
            targetStatesaddress <= std_logic_vector(statesIndex);
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            busy <= '0';
                            startGeneration <= '0';
                            startCache <= '0';
                            cacheRead <= true;
                            internalState <= CheckForJob;
                            statesIndex <= (others => '0');
                            ringletIndex <= 0;
                            targetStatesready <= '0';
                            targetStateswe <= '0';
                            targetStatesdata <= (others => '0');
                        when CheckForJob =>
                            if (ready = '1') then
                                if (read = '1') then
                                    startCache <= '1';
                                    busy <= '0';
                                    startGeneration <= '0';
                                else
                                    busy <= '1';
                                    startGeneration <= '1';
                                    internalState <= WaitForRunnerToStart;
                                end if;
                            else
                                startGeneration <= '0';
                                startCache <= '0';
                                cacheRead <= true;
                                busy <= '0';
                            end if;
                            targetStatesready <= '0';
                            targetStateswe <= '0';
                        when WaitForRunnerToStart =>
                            if (runnerBusy = '1') then
                                internalState <= WaitForRunnerToFinish;
                                startGeneration <= '0';
                            end if;
                            busy <= '1';
                            startCache <= '0';
                            targetStatesready <= '0';
                            targetStateswe <= '0';
                        when WaitForRunnerToFinish =>
                            if (runnerBusy = '0') then
                                if (cacheBusy = '0') then
                                    internalState <= WaitForCacheToStart;
                                    startCache <= '1';
                                    cacheRead <= false;
                                else
                                    startCache <= '0';
                                    cacheRead <= true;
                                end if;
                            else
                                cacheRead <= true;
                                startCache <= '0';
                            end if;
                            startGeneration <= '0';
                            busy <= '1';
                            targetStatesready <= '0';
                            targetStateswe <= '0';
                        when WaitForCacheToStart =>
                            if (cacheBusy = '1') then
                                internalState <= WaitForReadEnable;
                                startCache <= '0';
                                statesIndex <= (others => '0');
                                ringletIndex <= 0;
                                targetStatesready <= '1';
                            else
                                targetStatesready <= '0';
                                startCache <= '1';
                            end if;
                            startGeneration <= '0';
                            busy <= '1';
                            cacheRead <= false;
                            targetStateswe <= '0';
                        when WaitForReadEnable =>
                            targetStateswe <= '0';
                            targetStatesready <= '1';
                            if (targetStatesen = '1') then
                                internalState <= WaitForRead;
                            end if;
                        when CheckForDuplicates =>
                            if (targetStatesen = '1' and targetStatesbusy = '0') then
                                if (statesIndex = 12) then
                                    internalState <= Error;
                                elsif (ringletIndex = 1) then
                                    internalState <= WaitForCacheToEnd;
                                elsif (ringlets(ringletIndex)(7) = '1') then
                                    if (targetStatesvalue_en = '1') then
                                        if (targetStatesvalue = encodedToStdLogic(ringlets(ringletIndex)(3 to 4)) & ringlets(ringletIndex)(5) & ringlets(ringletIndex)(6)) then
                                            internalState <= SetNextRinglet;
                                        else
                                            internalState <= SetNextTargetState;
                                        end if;
                                    elsif (statesIndex > unsigned(targetStateslastAddress)) then
                                        internalState <= AddToStates;
                                    else
                                        internalState <= SetNextTargetState;
                                    end if;
                                else
                                    internalState <= SetNextRinglet;
                                end if;
                            end if;
                            busy <= '1';
                            cacheRead <= false;
                            startGeneration <= '0';
                            startCache <= '0';
                            targetStateswe <= '0';
                            targetStatesready <= '1';
                        when SetNextTargetState =>
                            statesIndex <= statesIndex + 1;
                            targetStateswe <= '0';
                            targetStatesready <= '1';
                            internalState <= WaitForRead;
                        when WaitForRead =>
                            targetStateswe <= '0';
                            targetStatesready <= '1';
                            internalState <= CheckForDuplicates;
                        when SetNextRinglet =>
                            ringletIndex <= ringletIndex + 1;
                            statesIndex <= (others => '0');
                            targetStateswe <= '0';
                            targetStatesready <= '1';
                            internalState <= WaitForRead;
                        when AddToStates =>
                            targetStatesdata <= encodedToStdLogic(ringlets(ringletIndex)(3 to 4)) & ringlets(ringletIndex)(5) & ringlets(ringletIndex)(6);
                            targetStateswe <= '1';
                            targetStatesready <= '1';
                            busy <= '1';
                            cacheRead <= false;
                            startGeneration <= '0';
                            startCache <= '0';
                            if (targetStatesen = '1') then
                                internalState <= ResetStateIndex;
                                ringletIndex <= ringletIndex + 1;
                            end if;
                        when WaitForCacheToEnd =>
                            startCache <= '0';
                            busy <= '1';
                            cacheRead <= false;
                            if (cacheBusy = '0') then
                                internalState <= CheckForJob;
                            end if;
                            targetStatesready <= '0';
                            targetStateswe <= '0';
                        when ResetStateIndex =>
                            targetStatesready <= '1';
                            targetStateswe <= '0';
                            statesIndex <= (others => '0');
                            busy <= '1';
                            cacheRead <= false;
                            startGeneration <= '0';
                            startCache <= '0';
                            internalState <= WaitForRead;
                        when others =>
                            null;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

}

// swiftlint:enable type_body_length
// swiftlint:enable file_length
