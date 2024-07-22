// GeneratorTests.swift
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

/// Test class for `generator` extensions.
final class GeneratorTests: XCTestCase {

    // swiftlint:disable force_unwrapping

    /// The machine to generate.
    let representation = MachineRepresentation(machine: .pingMachine, name: .pingMachine)!

    // swiftlint:enable force_unwrapping

    // swiftlint:disable function_body_length
    // swiftlint:disable line_length

    /// Test the generator is created correctly for sequential execution.
    func testSequentialGeneration() {
        guard let result = VHDLFile(sequentialGeneratorFor: representation) else {
            XCTFail("Failed to generate generator!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;
        use work.PrimitiveTypes.all;
        use work.PingMachineTypes.all;

        entity PingMachineGenerator is
            port(
                clk: in std_logic;
                InitialAddress: in std_logic_vector(31 downto 0);
                InitialRead: in std_logic;
                InitialReadReady: in std_logic;
                InitialValue: out std_logic_vector(31 downto 0);
                InitialLastAddress: out std_logic_vector(31 downto 0);
                WaitForPongAddress: in std_logic_vector(31 downto 0);
                WaitForPongRead: in std_logic;
                WaitForPongReadReady: in std_logic;
                WaitForPongValue: out std_logic_vector(31 downto 0);
                WaitForPongLastAddress: out std_logic_vector(31 downto 0);
                finished: out std_logic
            );
        end PingMachineGenerator;

        architecture Behavioral of PingMachineGenerator is
            type PingMachineGeneratorInternalState_t is (Initial, SetRead, ResetRead, IncrementIndex, SetJob, CheckIfFinished, HasFinished, StartInitial, ResetInitial, StartWaitForPong, ResetWaitForPong);
            signal currentState: PingMachineGeneratorInternalState_t := Initial;
            signal pendingStateIndex: unsigned(3 downto 0);
            signal currentTargetState: std_logic_vector(2 downto 0);
            signal Initialping: std_logic;
            signal InitialexecuteOnEntry: boolean;
            signal targetStatesaddress1: std_logic_vector(3 downto 0);
            signal targetStatesdata1: std_logic_vector(2 downto 0);
            signal targetStateswe1: std_logic;
            signal targetStatesready1: std_logic;
            signal targetStatesen1: std_logic;
            signal InitialReady: std_logic;
            signal InitialBusy: std_logic;
            signal WaitForPongping: std_logic;
            signal WaitForPongexecuteOnEntry: boolean;
            signal targetStatesaddress2: std_logic_vector(3 downto 0);
            signal targetStatesdata2: std_logic_vector(2 downto 0);
            signal targetStateswe2: std_logic;
            signal targetStatesready2: std_logic;
            signal targetStatesen2: std_logic;
            signal WaitForPongReady: std_logic;
            signal WaitForPongBusy: std_logic;
            signal targetStatesaddress0: std_logic_vector(3 downto 0);
            signal targetStatesdata0: std_logic_vector(2 downto 0);
            signal targetStateswe0: std_logic;
            signal targetStatesready0: std_logic;
            signal targetStatesen0: std_logic;
            signal targetStatesvalue: std_logic_vector(2 downto 0);
            signal targetStatesvalue_en: std_logic;
            signal targetStatesbusy: std_logic;
            signal targetStateslastAddress: std_logic_vector(3 downto 0);
            signal genInitialReady: std_logic;
            signal genWaitForPongReady: std_logic;
            component InitialGenerator is
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
            end component;
            component WaitForPongGenerator is
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
            end component;
            component PingMachineTargetStatesCacheMonitor is
                port(
                    clk: in std_logic;
                    address0: in std_logic_vector(3 downto 0);
                    data0: in std_logic_vector(2 downto 0);
                    we0: in std_logic;
                    ready0: in std_logic;
                    en0: out std_logic;
                    address1: in std_logic_vector(3 downto 0);
                    data1: in std_logic_vector(2 downto 0);
                    we1: in std_logic;
                    ready1: in std_logic;
                    en1: out std_logic;
                    address2: in std_logic_vector(3 downto 0);
                    data2: in std_logic_vector(2 downto 0);
                    we2: in std_logic;
                    ready2: in std_logic;
                    en2: out std_logic;
                    value: out std_logic_vector(2 downto 0);
                    value_en: out std_logic;
                    busy: out std_logic;
                    lastAddress: out std_logic_vector(3 downto 0)
                );
            end component;
        begin
            Initial_generator_inst: component InitialGenerator port map (
                clk => clk,
                ping => Initialping,
                executeOnEntry => InitialexecuteOnEntry,
                address => InitialAddress,
                ready => genInitialReady,
                read => InitialRead,
                busy => InitialBusy,
                targetStatesaddress => targetStatesaddress1,
                targetStatesdata => targetStatesdata1,
                targetStateswe => targetStateswe1,
                targetStatesready => targetStatesready1,
                targetStatesbusy => targetStatesbusy,
                targetStatesvalue => targetStatesvalue,
                targetStatesvalue_en => targetStatesvalue_en,
                targetStateslastAddress => targetStateslastAddress,
                targetStatesen => targetStatesen1,
                value => InitialValue,
                lastAddress => InitialLastAddress
            );
            WaitForPong_generator_inst: component WaitForPongGenerator port map (
                clk => clk,
                ping => WaitForPongping,
                executeOnEntry => WaitForPongexecuteOnEntry,
                address => WaitForPongAddress,
                ready => genWaitForPongReady,
                read => WaitForPongRead,
                busy => WaitForPongBusy,
                targetStatesaddress => targetStatesaddress2,
                targetStatesdata => targetStatesdata2,
                targetStateswe => targetStateswe2,
                targetStatesready => targetStatesready2,
                targetStatesbusy => targetStatesbusy,
                targetStatesvalue => targetStatesvalue,
                targetStatesvalue_en => targetStatesvalue_en,
                targetStateslastAddress => targetStateslastAddress,
                targetStatesen => targetStatesen2,
                value => WaitForPongValue,
                lastAddress => WaitForPongLastAddress
            );
            cache_inst: component PingMachineTargetStatesCacheMonitor port map (
                clk => clk,
                address0 => targetStatesaddress0,
                data0 => targetStatesdata0,
                we0 => targetStateswe0,
                ready0 => targetStatesready0,
                en0 => targetStatesen0,
                address1 => targetStatesaddress1,
                data1 => targetStatesdata1,
                we1 => targetStateswe1,
                ready1 => targetStatesready1,
                en1 => targetStatesen1,
                address2 => targetStatesaddress2,
                data2 => targetStatesdata2,
                we2 => targetStateswe2,
                ready2 => targetStatesready2,
                en2 => targetStatesen2,
                value => targetStatesvalue,
                value_en => targetStatesvalue_en,
                busy => targetStatesbusy,
                lastAddress => targetStateslastAddress
            );
            targetStatesaddress0 <= std_logic_vector(pendingStateIndex);
            genInitialReady <= InitialReadReady when currentState = HasFinished else InitialReady;
            genWaitForPongReady <= WaitForPongReadReady when currentState = HasFinished else WaitForPongReady;
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case currentState is
                        when Initial =>
                            targetStatesdata0 <= "001";
                            currentTargetState <= "001";
                            targetStateswe0 <= '1';
                            targetStatesready0 <= '1';
                            finished <= '0';
                            pendingStateIndex <= (others => '0');
                            Initialping <= '0';
                            InitialexecuteOnEntry <= false;
                            InitialReady <= '0';
                            WaitForPongping <= '0';
                            WaitForPongexecuteOnEntry <= false;
                            WaitForPongReady <= '0';
                            if (targetStatesen0 = '1') then
                                currentState <= ResetRead;
                            end if;
                        when SetRead =>
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '1';
                            if (targetStatesen0 = '1') then
                                currentState <= SetJob;
                            end if;
                        when ResetRead =>
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                            if (targetStatesen0 = '0') then
                                currentState <= SetRead;
                            end if;
                        when IncrementIndex =>
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                            pendingStateIndex <= pendingStateIndex + 1;
                            currentState <= ResetRead;
                        when SetJob =>
                            if (targetStatesen0 = '1') then
                                if (targetStatesvalue_en = '1' and targetStatesaddress0 <= targetStateslastAddress) then
                                    if (targetStatesvalue(1 downto 1) = STATE_Initial) then
                                        if (InitialBusy = '0') then
                                            currentState <= StartInitial;
                                        else
                                            currentState <= ResetRead;
                                        end if;
                                    elsif (targetStatesvalue(1 downto 1) = STATE_WaitForPong) then
                                        if (WaitForPongBusy = '0') then
                                            currentState <= StartWaitForPong;
                                        else
                                            currentState <= ResetRead;
                                        end if;
                                    end if;
                                    currentTargetState <= targetStatesvalue;
                                else
                                    currentState <= CheckIfFinished;
                                end if;
                            end if;
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '1';
                        when StartInitial =>
                            Initialping <= currentTargetState(2);
                            InitialexecuteOnEntry <= stdLogicToBool(currentTargetState(0));
                            InitialReady <= '1';
                            currentState <= ResetInitial;
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                        when ResetInitial =>
                            if (InitialBusy = '1') then
                                InitialReady <= '0';
                                currentState <= IncrementIndex;
                            end if;
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                        when StartWaitForPong =>
                            WaitForPongping <= currentTargetState(2);
                            WaitForPongexecuteOnEntry <= stdLogicToBool(currentTargetState(0));
                            WaitForPongReady <= '1';
                            currentState <= ResetWaitForPong;
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                        when ResetWaitForPong =>
                            if (WaitForPongBusy = '1') then
                                WaitForPongReady <= '0';
                                currentState <= IncrementIndex;
                            end if;
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                        when CheckIfFinished =>
                            if (InitialBusy = '0' and WaitForPongBusy = '0' and targetStatesvalue_en = '0' and targetStatesen0 = '1') then
                                currentState <= HasFinished;
                            else
                                currentState <= ResetRead;
                            end if;
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '1';
                        when HasFinished =>
                            finished <= '1';
                            targetStateswe0 <= '0';
                            targetStatesready0 <= '0';
                        when others =>
                            null;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

    /// Test the generator is created correctly.
    func testGeneration() {
        guard let result = VHDLFile(concurrentGeneratorFor: representation) else {
            XCTFail("Failed to generate generator!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;
        use work.PrimitiveTypes.all;
        use work.PingMachineTypes.all;

        entity PingMachineGenerator is
            port(
                clk: in std_logic;
                InitialAddress: in std_logic_vector(31 downto 0);
                InitialRead: in std_logic;
                InitialReadReady: in std_logic;
                InitialValue: out std_logic_vector(31 downto 0);
                InitialLastAddress: out std_logic_vector(31 downto 0);
                WaitForPongAddress: in std_logic_vector(31 downto 0);
                WaitForPongRead: in std_logic;
                WaitForPongReadReady: in std_logic;
                WaitForPongValue: out std_logic_vector(31 downto 0);
                WaitForPongLastAddress: out std_logic_vector(31 downto 0);
                finished: out std_logic
            );
        end PingMachineGenerator;

        architecture Behavioral of PingMachineGenerator is
            signal fromState: std_logic_vector(7 downto 0);
            signal nextState: std_logic_vector(7 downto 0);
            signal currentState: std_logic_vector(7 downto 0) := "00000000";
            constant Initial: std_logic_vector(7 downto 0) := "00000000";
            constant SetJob: std_logic_vector(7 downto 0) := "00000001";
            constant CheckForDuplicate: std_logic_vector(7 downto 0) := "00000010";
            constant VerifyDuplicate: std_logic_vector(7 downto 0) := "00000011";
            constant CheckIfFinished: std_logic_vector(7 downto 0) := "00000100";
            constant VerifyFinished: std_logic_vector(7 downto 0) := "00000101";
            constant HasFinished: std_logic_vector(7 downto 0) := "00000110";
            constant ChooseNextInsertion: std_logic_vector(7 downto 0) := "00000111";
            constant HasError: std_logic_vector(7 downto 0) := "00001000";
            constant UpdateInitialPendingStates: std_logic_vector(7 downto 0) := "00001001";
            constant StartInitial: std_logic_vector(7 downto 0) := "00001010";
            constant ResetInitialReady: std_logic_vector(7 downto 0) := "00001011";
            constant CheckInitialFinished: std_logic_vector(7 downto 0) := "00001100";
            constant UpdateWaitForPongPendingStates: std_logic_vector(7 downto 0) := "00001101";
            constant StartWaitForPong: std_logic_vector(7 downto 0) := "00001110";
            constant ResetWaitForPongReady: std_logic_vector(7 downto 0) := "00001111";
            constant CheckWaitForPongFinished: std_logic_vector(7 downto 0) := "00010000";
            signal pendingStates: Pending_States_t := (others => (others => '0'));
            signal observedStates: TargetStates_t := (others => (others => '0'));
            signal pendingStateIndex: integer range 0 to 24;
            signal observedIndex: integer range 0 to 12;
            signal pendingSearchIndex: integer range 0 to 23;
            signal observedSearchIndex: integer range 0 to 11;
            signal pendingInsertIndex: integer range 0 to 24;
            signal maxInsertIndex: integer range 0 to 24;
            signal Initialping: std_logic;
            signal InitialexecuteOnEntry: boolean;
            signal InitialReady: std_logic;
            signal InitialBusy: std_logic;
            signal InitialTargetStates: TargetStates_t;
            signal InitialWorking: boolean;
            signal InitialIndex: integer range 0 to 12;
            signal currentInitialTargetState: std_logic_vector(3 downto 0);
            signal WaitForPongping: std_logic;
            signal WaitForPongexecuteOnEntry: boolean;
            signal WaitForPongReady: std_logic;
            signal WaitForPongBusy: std_logic;
            signal WaitForPongTargetStates: TargetStates_t;
            signal WaitForPongWorking: boolean;
            signal WaitForPongIndex: integer range 0 to 12;
            signal currentWaitForPongTargetState: std_logic_vector(3 downto 0);
            signal isDuplicate: boolean;
            signal isFinished: boolean;
            signal currentObservedState: std_logic_vector(3 downto 0);
            signal currentPendingState: std_logic_vector(3 downto 0);
            signal currentWorkingPendingState: std_logic_vector(3 downto 0);
            signal genInitialReady: std_logic;
            signal genWaitForPongReady: std_logic;
            component InitialGenerator is
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
            end component;
            component WaitForPongGenerator is
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
            end component;
        begin
            currentObservedState <= observedStates(observedSearchIndex);
            currentPendingState <= pendingStates(pendingSearchIndex);
            currentWorkingPendingState <= pendingStates(pendingStateIndex);
            Initial_generator_inst: component InitialGenerator port map (
                clk => clk,
                ping => Initialping,
                executeOnEntry => InitialexecuteOnEntry,
                address => InitialAddress,
                ready => genInitialReady,
                read => InitialRead,
                busy => InitialBusy,
                targetStates => InitialTargetStates,
                value => InitialValue,
                lastAddress => InitialLastAddress
            );
            WaitForPong_generator_inst: component WaitForPongGenerator port map (
                clk => clk,
                ping => WaitForPongping,
                executeOnEntry => WaitForPongexecuteOnEntry,
                address => WaitForPongAddress,
                ready => genWaitForPongReady,
                read => WaitForPongRead,
                busy => WaitForPongBusy,
                targetStates => WaitForPongTargetStates,
                value => WaitForPongValue,
                lastAddress => WaitForPongLastAddress
            );
            genInitialReady <= InitialReadReady when currentState = HasFinished else InitialReady;
            currentInitialTargetState <= InitialTargetStates(InitialIndex);
            genWaitForPongReady <= WaitForPongReadReady when currentState = HasFinished else WaitForPongReady;
            currentWaitForPongTargetState <= WaitForPongTargetStates(WaitForPongIndex);
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case currentState is
                        when Initial =>
                            pendingStates(0) <= "0011";
                            finished <= '0';
                            pendingStateIndex <= 0;
                            observedIndex <= 0;
                            nextState <= Initial;
                            isDuplicate <= false;
                            isFinished <= false;
                            pendingInsertIndex <= 1;
                            maxInsertIndex <= 0;
                            fromState <= SetJob;
                            currentState <= SetJob;
                            observedSearchIndex <= 0;
                            pendingSearchIndex <= 0;
                            Initialping <= '0';
                            InitialexecuteOnEntry <= false;
                            InitialReady <= '0';
                            WaitForPongping <= '0';
                            WaitForPongexecuteOnEntry <= false;
                            WaitForPongReady <= '0';
                            InitialWorking <= false;
                            WaitForPongWorking <= false;
                        when SetJob =>
                            if (pendingStateIndex = 24 or pendingStateIndex > maxInsertIndex) then
                                currentState <= CheckIfFinished;
                                pendingStateIndex <= 0;
                                isFinished <= true;
                            elsif (currentWorkingPendingState(0) = '1') then
                                if (currentWorkingPendingState(2 downto 2) = STATE_Initial) then
                                    if (InitialBusy = '0') then
                                        nextState <= StartInitial;
                                        if (InitialWorking) then
                                            fromState <= UpdateInitialPendingStates;
                                            currentState <= ChooseNextInsertion;
                                            InitialIndex <= 0;
                                        else
                                            currentState <= CheckForDuplicate;
                                        end if;
                                    else
                                        nextState <= SetJob;
                                        currentState <= CheckIfFinished;
                                    end if;
                                elsif (currentWorkingPendingState(2 downto 2) = STATE_WaitForPong) then
                                    if (WaitForPongBusy = '0') then
                                        nextState <= StartWaitForPong;
                                        if (WaitForPongWorking) then
                                            fromState <= UpdateWaitForPongPendingStates;
                                            currentState <= ChooseNextInsertion;
                                            WaitForPongIndex <= 0;
                                        else
                                            currentState <= CheckForDuplicate;
                                        end if;
                                    else
                                        nextState <= SetJob;
                                        currentState <= CheckIfFinished;
                                    end if;
                                else
                                    nextState <= SetJob;
                                end if;
                            else
                                pendingStateIndex <= pendingStateIndex + 1;
                            end if;
                            isDuplicate <= false;
                        when UpdateInitialPendingStates =>
                            if (InitialIndex = 12) then
                                currentState <= CheckForDuplicate;
                            elsif (currentInitialTargetState(0) = '1') then
                                pendingStates(pendingInsertIndex) <= currentInitialTargetState;
                                currentState <= ChooseNextInsertion;
                                fromState <= UpdateInitialPendingStates;
                                InitialIndex <= InitialIndex + 1;
                                if (pendingInsertIndex > maxInsertIndex) then
                                    maxInsertIndex <= pendingInsertIndex;
                                end if;
                            else
                                currentState <= CheckForDuplicate;
                            end if;
                            isDuplicate <= false;
                            InitialWorking <= false;
                        when StartInitial =>
                            Initialping <= currentWorkingPendingState(3);
                            InitialexecuteOnEntry <= stdLogicToBool(currentWorkingPendingState(1));
                            InitialReady <= '1';
                            currentState <= ResetInitialReady;
                            InitialWorking <= true;
                        when ResetInitialReady =>
                            if (InitialBusy = '1') then
                                InitialReady <= '0';
                                pendingStates(pendingStateIndex)(0) <= '0';
                                observedStates(observedIndex) <= currentWorkingPendingState;
                                observedIndex <= observedIndex + 1;
                                pendingStateIndex <= pendingStateIndex + 1;
                                currentState <= SetJob;
                            end if;
                        when CheckInitialFinished =>
                            if (InitialBusy = '0') then
                                fromState <= UpdateInitialPendingStates;
                                currentState <= ChooseNextInsertion;
                                InitialIndex <= 0;
                            elsif (WaitForPongWorking) then
                                currentState <= CheckWaitForPongFinished;
                            else
                                currentState <= SetJob;
                            end if;
                            nextState <= SetJob;
                        when UpdateWaitForPongPendingStates =>
                            if (WaitForPongIndex = 12) then
                                currentState <= CheckForDuplicate;
                            elsif (currentWaitForPongTargetState(0) = '1') then
                                pendingStates(pendingInsertIndex) <= currentWaitForPongTargetState;
                                currentState <= ChooseNextInsertion;
                                fromState <= UpdateWaitForPongPendingStates;
                                WaitForPongIndex <= WaitForPongIndex + 1;
                                if (pendingInsertIndex > maxInsertIndex) then
                                    maxInsertIndex <= pendingInsertIndex;
                                end if;
                            else
                                currentState <= CheckForDuplicate;
                            end if;
                            isDuplicate <= false;
                            WaitForPongWorking <= false;
                        when StartWaitForPong =>
                            WaitForPongping <= currentWorkingPendingState(3);
                            WaitForPongexecuteOnEntry <= stdLogicToBool(currentWorkingPendingState(1));
                            WaitForPongReady <= '1';
                            currentState <= ResetWaitForPongReady;
                            WaitForPongWorking <= true;
                        when ResetWaitForPongReady =>
                            if (WaitForPongBusy = '1') then
                                WaitForPongReady <= '0';
                                pendingStates(pendingStateIndex)(0) <= '0';
                                observedStates(observedIndex) <= currentWorkingPendingState;
                                observedIndex <= observedIndex + 1;
                                pendingStateIndex <= pendingStateIndex + 1;
                                currentState <= SetJob;
                            end if;
                        when CheckWaitForPongFinished =>
                            if (WaitForPongBusy = '0') then
                                fromState <= UpdateWaitForPongPendingStates;
                                currentState <= ChooseNextInsertion;
                                WaitForPongIndex <= 0;
                            else
                                currentState <= SetJob;
                            end if;
                            nextState <= SetJob;
                        when ChooseNextInsertion =>
                            if (currentPendingState(0) = '0') then
                                pendingInsertIndex <= pendingSearchIndex;
                                currentState <= fromState;
                                pendingSearchIndex <= 0;
                            elsif (pendingSearchIndex = 23) then
                                currentState <= HasError;
                            else
                                pendingSearchIndex <= pendingSearchIndex + 1;
                            end if;
                        when CheckForDuplicate =>
                            if (currentObservedState(0) = '1') then
                                if (currentWorkingPendingState(3 downto 1) = currentObservedState(3 downto 1)) then
                                    isDuplicate <= true;
                                    currentState <= VerifyDuplicate;
                                    observedSearchIndex <= 0;
                                elsif (observedSearchIndex = 11) then
                                    currentState <= VerifyDuplicate;
                                    observedSearchIndex <= 0;
                                else
                                    observedSearchIndex <= observedSearchIndex + 1;
                                end if;
                            else
                                observedSearchIndex <= 0;
                                currentState <= VerifyDuplicate;
                            end if;
                        when VerifyDuplicate =>
                            if (isDuplicate) then
                                pendingStates(pendingStateIndex)(0) <= '0';
                                pendingStateIndex <= pendingStateIndex + 1;
                                currentState <= SetJob;
                                isDuplicate <= false;
                            else
                                currentState <= nextState;
                            end if;
                        when CheckIfFinished =>
                            if (InitialWorking) then
                                isFinished <= false;
                                currentState <= CheckInitialFinished;
                            elsif (WaitForPongWorking) then
                                isFinished <= false;
                                currentState <= CheckWaitForPongFinished;
                            elsif (currentPendingState(0) = '1') then
                                isFinished <= false;
                                pendingSearchIndex <= 0;
                                currentState <= VerifyFinished;
                            elsif (pendingSearchIndex = 23) then
                                currentState <= VerifyFinished;
                                pendingSearchIndex <= 0;
                            else
                                pendingSearchIndex <= pendingSearchIndex + 1;
                            end if;
                        when VerifyFinished =>
                            if (isFinished) then
                                currentState <= HasFinished;
                            else
                                currentState <= SetJob;
                            end if;
                        when HasFinished =>
                            finished <= '1';
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
