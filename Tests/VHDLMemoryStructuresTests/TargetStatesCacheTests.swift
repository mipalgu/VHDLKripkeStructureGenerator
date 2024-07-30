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

    /// Test generations create VHDL files.
    func testAllGeneration() {
        XCTAssertNotNil(VHDLFile(targetStatesBRAMFor: representation))
        XCTAssertNotNil(VHDLFile(targetStatesCacheFor: representation))
        XCTAssertNotNil(VHDLFile(targetStatesDecoderFor: representation))
        XCTAssertNotNil(VHDLFile(targetStatesEncoderFor: representation))
        XCTAssertNotNil(VHDLFile(targetStatesDividerFor: representation))
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable line_length

    /// Test BRAM generation is correct.
    func testBRAM() {
        guard let result = VHDLFile(targetStatesBRAMFor: representation) else {
            XCTFail("Failed to create BRAM!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;

        entity PingMachineTargetStatesCacheBRAM is
            port(
                clk: in std_logic;
                we: in std_logic;
                addr: in std_logic_vector(31 downto 0);
                di: in std_logic_vector(31 downto 0);
                do: out std_logic_vector(31 downto 0)
            );
        end PingMachineTargetStatesCacheBRAM;

        architecture Behavioral of PingMachineTargetStatesCacheBRAM is
            type PingMachineTargetStatesCacheBRAMRAM_t is array (0 to 2) of std_logic_vector(31 downto 0);
            signal ram: PingMachineTargetStatesCacheBRAMRAM_t;
        begin
            process(clk)
            begin
                if (rising_edge(clk)) then
                    if (we = '1') then
                        ram(to_integer(unsigned(addr))) <= di;
                    end if;
                    do <= ram(to_integer(unsigned(addr)));
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

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

        entity PingMachineTargetStatesCache is
            port(
                clk: in std_logic;
                address: in std_logic_vector(3 downto 0);
                data: in std_logic_vector(2 downto 0);
                we: in std_logic;
                ready: in std_logic;
                busy: out std_logic;
                value: out std_logic_vector(2 downto 0);
                value_en: out std_logic;
                lastAddress: out std_logic_vector(3 downto 0)
            );
        end PingMachineTargetStatesCache;

        architecture Behavioral of PingMachineTargetStatesCache is
            type PingMachineTargetStatesCacheCache_t is array (0 to 3) of std_logic_vector(2 downto 0);
            signal cache: PingMachineTargetStatesCacheCache_t;
            signal cacheIndex: integer range 0 to 3;
            signal memoryIndex: integer range 0 to 3;
            signal genIndex: std_logic_vector(31 downto 0);
            signal di: std_logic_vector(31 downto 0);
            signal index: std_logic_vector(31 downto 0);
            signal weBRAM: std_logic;
            signal currentValue: std_logic_vector(31 downto 0);
            signal memoryAddress: std_logic_vector(31 downto 0);
            type PingMachineTargetStatesCacheEnables_t is array (0 to 3) of std_logic;
            signal enables: PingMachineTargetStatesCacheEnables_t;
            signal readEnables: PingMachineTargetStatesCacheEnables_t;
            signal readCache: PingMachineTargetStatesCacheCache_t;
            signal result: std_logic_vector(3 downto 0);
            signal remainder: std_logic_vector(3 downto 0);
            signal unsignedLastAddress: unsigned(3 downto 0);
            signal currentIndex: unsigned(3 downto 0);
            type PingMachineTargetStatesCacheInternalState_t is (Initial, WaitForNewData, WriteElement, IncrementIndex, ResetEnables, Error);
            signal internalState: PingMachineTargetStatesCacheInternalState_t;
            component PingMachineTargetStatesCacheEncoder is
                port(
                    in0: in std_logic_vector(2 downto 0);
                    in0en: in std_logic;
                    in1: in std_logic_vector(2 downto 0);
                    in1en: in std_logic;
                    in2: in std_logic_vector(2 downto 0);
                    in2en: in std_logic;
                    in3: in std_logic_vector(2 downto 0);
                    in3en: in std_logic;
                    data: out std_logic_vector(31 downto 0)
                );
            end component;
            component PingMachineTargetStatesCacheDecoder is
                port(
                    data: in std_logic_vector(31 downto 0);
                    out0: out std_logic_vector(2 downto 0);
                    out0en: out std_logic;
                    out1: out std_logic_vector(2 downto 0);
                    out1en: out std_logic;
                    out2: out std_logic_vector(2 downto 0);
                    out2en: out std_logic;
                    out3: out std_logic_vector(2 downto 0);
                    out3en: out std_logic
                );
            end component;
            component PingMachineTargetStatesCacheDivider is
                generic(
                    divisor: integer range 0 to 4
                );
                port(
                    numerator: in std_logic_vector(3 downto 0);
                    result: out std_logic_vector(3 downto 0);
                    remainder: out std_logic_vector(3 downto 0)
                );
            end component;
            component PingMachineTargetStatesCacheBRAM is
                port(
                    clk: in std_logic;
                    we: in std_logic;
                    addr: in std_logic_vector(31 downto 0);
                    di: in std_logic_vector(31 downto 0);
                    do: out std_logic_vector(31 downto 0)
                );
            end component;
        begin
            PingMachineTargetStatesCacheEncoder_inst: component PingMachineTargetStatesCacheEncoder port map (
                in0 => cache(0),
                in0en => enables(0),
                in1 => cache(1),
                in1en => enables(1),
                in2 => cache(2),
                in2en => enables(2),
                in3 => cache(3),
                in3en => enables(3),
                data => di
            );
            PingMachineTargetStatesCacheDecoder_inst: component PingMachineTargetStatesCacheDecoder port map (
                data => currentValue,
                out0 => readCache(0),
                out0en => readEnables(0),
                out1 => readCache(1),
                out1en => readEnables(1),
                out2 => readCache(2),
                out2en => readEnables(2),
                out3 => readCache(3),
                out3en => readEnables(3)
            );
            PingMachineTargetStatesCacheDivider_inst: component PingMachineTargetStatesCacheDivider
                generic map (
                    divisor => 2
                )
                port map (
                    numerator => address,
                    result => result,
                    remainder => remainder
                );
            PingMachineTargetStatesCacheBRAM_inst: component PingMachineTargetStatesCacheBRAM port map (
                clk => clk,
                we => weBRAM,
                addr => index,
                di => di,
                do => currentValue
            );
            memoryAddress <= "0000000000000000000000000000" & result;
            value <= readCache(to_integer(unsigned(remainder)));
            value_en <= readEnables(to_integer(unsigned(remainder)));
            index <= memoryAddress when ready = '1' and we /= '1' and internalState = WaitForNewData else genIndex;
            genIndex <= std_logic_vector(to_unsigned(memoryIndex, 32));
            lastAddress <= std_logic_vector(unsignedLastAddress);
            currentIndex <= resize(to_unsigned(memoryIndex, 4) * 4, 4) + to_unsigned(cacheIndex, 4);
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            cache <= (others => (others => '0'));
                            enables <= (others => '0');
                            cacheIndex <= 0;
                            weBRAM <= '0';
                            unsignedLastAddress <= (others => '0');
                            busy <= '0';
                            memoryIndex <= 0;
                            internalState <= WaitForNewData;
                        when WaitForNewData =>
                            if (ready = '1' and we = '1') then
                                internalState <= WriteElement;
                                busy <= '1';
                                cache(cacheIndex) <= data;
                                enables(cacheIndex) <= '1';
                            else
                                internalState <= WaitForNewData;
                                busy <= '0';
                                cache(cacheIndex) <= (others => '0');
                                enables(cacheIndex) <= '0';
                            end if;
                            weBRAM <= '0';
                        when WriteElement =>
                            if (memoryIndex = 3) then
                                internalState <= Error;
                                weBRAM <= '0';
                            elsif (cacheIndex = 3) then
                                weBRAM <= '1';
                                internalState <= ResetEnables;
                                if (unsignedLastAddress < currentIndex) then
                                    unsignedLastAddress <= currentIndex;
                                end if;
                            else
                                weBRAM <= '1';
                                internalState <= IncrementIndex;
                                if (unsignedLastAddress < currentIndex) then
                                    unsignedLastAddress <= currentIndex;
                                end if;
                            end if;
                            busy <= '1';
                        when IncrementIndex =>
                            weBRAM <= '0';
                            cacheIndex <= cacheIndex + 1;
                            busy <= '1';
                            internalState <= WaitForNewData;
                        when ResetEnables =>
                            weBRAM <= '0';
                            cacheIndex <= 0;
                            cache <= (others => (others => '0'));
                            enables <= (others => '0');
                            busy <= '1';
                            memoryIndex <= memoryIndex + 1;
                            internalState <= WaitForNewData;
                        when others =>
                            internalState <= Error;
                            busy <= '1';
                            weBRAM <= '0';
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
    }

    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

}
