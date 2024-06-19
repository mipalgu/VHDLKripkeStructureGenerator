// TargetStatesCacheTests.swift
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
import VHDLMachines
@testable import VHDLMemoryStructures
import VHDLParsing
import XCTest

/// Test class for `TargetStatesCach`.
final class TargetStatesCacheTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A test machine.
    let representation: MachineRepresentation! = MachineRepresentation(
        machine: .pingMachine, name: .pingMachine
    )

    // swiftlint:enable implicitly_unwrapped_optional

    /// Test cache generation.
    func testGeneration() {
        guard let result = VHDLFile(targetStatesCacheFor: representation) else {
            XCTFail("Failed to create cache!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;
        use work.PingMachineTypes.all;

        entity TargetStatesCache is
            port(
                clk: in std_logic;
                state: in std_logic_vector(2 downto 0);
                address: in std_logic_vector(3 downto 0);
                we: in std_logic;
                ready: in std_logic;
                value: out std_logic_vector(3 downto 0);
                busy: out std_logic;
                lastAddress: out std_logic_vector(3 downto 0)
            );
        end TargetStatesCache;

        architecture Behavioral of TargetStatesCache is
            signal workingStates: TargetStatesBRAMElement_t;
            signal memoryIndex: integer range 0 to 2;
            signal di: std_logic_vector(31 downto 0);
            signal index: std_logic_vector(31 downto 0);
            signal weBRAM: std_logic;
            signal enables: TargetStatesBRAMEnabled_t;
            signal genIndex: std_logic_vector(3 downto 0);
            type TargetStatesCache_InternalState_t is (Initial, WaitForNewRinglets, WriteElement, Error, ResetEnables, IncrementIndex);
            signal internalState: TargetStatesCache_InternalState_t := Initial;
            signal stateIndex: integer range 0 to 6;
            signal memoryAddress: std_logic_vector(31 downto 0);
            signal memoryOffset: integer range 0 to 6;
            signal currentValue: std_logic_vector(31 downto 0);
            signal readStates: TargetStatesBRAMElement_t;
            signal readEnables: TargetStatesBRAMEnabled_t;
            component TargetStatesBRAM is
                port(
                    clk: in std_logic;
                    we: in std_logic;
                    addr: in std_logic_vector(31 downto 0);
                    di: in std_logic_vector(31 downto 0);
                    do: out std_logic_vector(31 downto 0)
                );
            end component;
            component TargetStatesEncoder is
                port(
                    clk: in std_logic;
                    state0: in std_logic_vector(2 downto 0);
                    state0en: in std_logic;
                    state1: in std_logic_vector(2 downto 0);
                    state1en: in std_logic;
                    state2: in std_logic_vector(2 downto 0);
                    state2en: in std_logic;
                    state3: in std_logic_vector(2 downto 0);
                    state3en: in std_logic;
                    state4: in std_logic_vector(2 downto 0);
                    state4en: in std_logic;
                    state5: in std_logic_vector(2 downto 0);
                    state5en: in std_logic;
                    state6: in std_logic_vector(2 downto 0);
                    state6en: in std_logic;
                    data: out std_logic_vector(31 downto 0)
                );
            end component;
            component TargetStatesDecoder is
                port(
                    data: in std_logic_vector(31 downto 0);
                    state0: out std_logic_vector(2 downto 0);
                    state0en: out std_logic;
                    state1: out std_logic_vector(2 downto 0);
                    state1en: out std_logic;
                    state2: out std_logic_vector(2 downto 0);
                    state2en: out std_logic;
                    state3: out std_logic_vector(2 downto 0);
                    state3en: out std_logic;
                    state4: out std_logic_vector(2 downto 0);
                    state4en: out std_logic;
                    state5: out std_logic_vector(2 downto 0);
                    state5en: out std_logic;
                    state6: out std_logic_vector(2 downto 0);
                    state6en: out std_logic
                );
            end component;
        begin
            bram_inst: component TargetStatesBRAM port map (
                clk => clk,
                we => weBRAM,
                addr => index,
                di => di,
                do => currentValue
            );
            encoder_inst: component TargetStatesEncoder port map (
                clk => clk,
                state0 => workingStates(0),
                state0en => enables(0),
                state1 => workingStates(1),
                state1en => enables(1),
                state2 => workingStates(2),
                state2en => enables(2),
                state3 => workingStates(3),
                state3en => enables(3),
                state4 => workingStates(4),
                state4en => enables(4),
                state5 => workingStates(5),
                state5en => enables(5),
                state6 => workingStates(6),
                state6en => enables(6),
                data => di
            );
            decoder_inst: component TargetStatesDecoder port map (
                data => currentValue,
                state0 => readStates(0),
                state0en => readEnables(0),
                state1 => readStates(1),
                state1en => readEnables(1),
                state2 => readStates(2),
                state2en => readEnables(2),
                state3 => readStates(3),
                state3en => readEnables(3),
                state4 => readStates(4),
                state4en => readEnables(4),
                state5 => readStates(5),
                state5en => readEnables(5),
                state6 => readStates(6),
                state6en => readEnables(6)
            );
            memoryAddress <= "0000000000000000000000000000" & std_logic_vector(unsigned(address) / 7);
            memoryOffset <= to_integer(unsigned(address) - unsigned(address) / 7 * 7);
            value <= readStates(memoryOffset) & readEnables(memoryOffset);
            index <= memoryAddress when ready = '1' and we /= '1' and internalState = WaitForNewRinglets else genIndex;
            genIndex <= std_logic_vector(to_unsigned(memoryIndex, 4) * 7 + to_unsigned(stateIndex, 4));
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            busy <= '0';
                            internalState <= WaitForNewRinglets;
                            memoryIndex <= 0;
                            weBRAM <= '0';
                            di <= (others => '0');
                            stateIndex <= 0;
                            enables <= (others => '0');
                        when WaitForNewRinglets =>
                            if (ready = '1' and we = '1') then
                                internalState <= WriteElement;
                                busy <= '1';
                                workingStates(stateIndex) <= state;
                            else
                                busy <= '0';
                            end if;
                            weBRAM <= '0';
                        when WriteElement =>
                            if (memoryIndex = 2) then
                                internalState <= Error;
                                weBRAM <= '0';
                            elsif (stateIndex = 6) then
                                internalState <= ResetEnables;
                                weBRAM <= '1';
                            else
                                internalState <= IncrementIndex;
                                weBRAM <= '1';
                            end if;
                            lastAddress <= genIndex;
                            enables(stateIndex) <= '1';
                            workingStates(stateIndex) <= state;
                            busy <= '1';
                        when IncrementIndex =>
                            weBRAM <= '0';
                            stateIndex <= stateIndex + 1;
                            busy <= '1';
                            internalState <= WaitForNewRinglets;
                        when ResetEnables =>
                            weBRAM <= '0';
                            enables <= (others => '0');
                            workingStates <= (others => (others => '0'));
                            busy <= '1';
                            memoryIndex <= memoryIndex + 1;
                            stateIndex <= 0;
                            internalState <= WaitForNewRinglets;
                        when others =>
                            null;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
    }

}
