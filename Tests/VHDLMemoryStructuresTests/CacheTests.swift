// CacheTests.swift
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
import Utilities
@testable import VHDLMemoryStructures
import VHDLParsing
import XCTest

/// Test class for cache.
final class CacheTests: XCTestCase {

    // swiftlint:disable function_body_length
    // swiftlint:disable line_length

    /// Test cache generation.
    func testCacheGeneration() {
        guard let result = VHDLFile(
            cacheName: .targetStatesCache, elementSize: 3, numberOfElements: 12
        ) else {
            XCTFail("Failed to create cache!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;

        entity TargetStatesCache is
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
        end TargetStatesCache;

        architecture Behavioral of TargetStatesCache is
            type TargetStatesCacheCache_t is array (0 to 3) of std_logic_vector(2 downto 0);
            signal cache: TargetStatesCacheCache_t;
            signal cacheIndex: integer range 0 to 3;
            signal memoryIndex: integer range 0 to 3;
            signal genIndex: std_logic_vector(31 downto 0);
            signal di: std_logic_vector(31 downto 0);
            signal index: std_logic_vector(31 downto 0);
            signal weBRAM: std_logic;
            signal currentValue: std_logic_vector(31 downto 0);
            signal memoryAddress: std_logic_vector(31 downto 0);
            type TargetStatesCacheEnables_t is array (0 to 3) of std_logic;
            signal enables: TargetStatesCacheEnables_t;
            signal readEnables: TargetStatesCacheEnables_t;
            signal readCache: TargetStatesCacheCache_t;
            signal result: std_logic_vector(3 downto 0);
            signal remainder: std_logic_vector(3 downto 0);
            signal readValue: integer range 0 to 3;
            signal unsignedLastAddress: unsigned(3 downto 0);
            signal currentIndex: unsigned(3 downto 0);
            type TargetStatesCacheInternalState_t is (Initial, WaitForNewData, WriteElement, IncrementIndex, ResetEnables, Error);
            signal internalState: TargetStatesCacheInternalState_t;
            component TargetStatesCacheEncoder is
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
            component TargetStatesCacheDecoder is
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
            component TargetStatesCacheDivider is
                generic(
                    divisor: integer range 0 to 4
                );
                port(
                    numerator: in std_logic_vector(3 downto 0);
                    result: out std_logic_vector(3 downto 0);
                    remainder: out std_logic_vector(3 downto 0)
                );
            end component;
            component TargetStatesCacheBRAM is
                port(
                    clk: in std_logic;
                    we: in std_logic;
                    addr: in std_logic_vector(31 downto 0);
                    di: in std_logic_vector(31 downto 0);
                    do: out std_logic_vector(31 downto 0)
                );
            end component;
        begin
            TargetStatesCacheEncoder_inst: component TargetStatesCacheEncoder port map (
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
            TargetStatesCacheDecoder_inst: component TargetStatesCacheDecoder port map (
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
            TargetStatesCacheDivider_inst: component TargetStatesCacheDivider
                generic map (
                    divisor => 2
                )
                port map (
                    numerator => address,
                    result => result,
                    remainder => remainder
                );
            TargetStatesCacheBRAM_inst: component TargetStatesCacheBRAM port map (
                clk => clk,
                we => weBRAM,
                addr => index,
                di => di,
                do => currentValue
            );
            memoryAddress <= "0000000000000000000000000000" & result;
            value <= readCache(readValue);
            value_en <= readEnables(readValue);
            index <= memoryAddress when ready = '1' and we /= '1' and internalState = WaitForNewData else genIndex;
            genIndex <= std_logic_vector(to_unsigned(memoryIndex, 32));
            lastAddress <= std_logic_vector(unsignedLastAddress);
            currentIndex <= resize(to_unsigned(memoryIndex, 4) * 4, 4) + to_unsigned(cacheIndex, 4);
            process(clk)
            begin
                if (rising_edge(clk)) then
                    readValue <= to_integer(unsigned(remainder));
                end if;
            end process;
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
        XCTAssertEqual(result.rawValue, expected)
    }

    /// Test cache generation.
    func testLargeCacheGeneration() {
        guard let result = VHDLFile(
            cacheName: .targetStatesCache, elementSize: 58, numberOfElements: 5
        ) else {
            XCTFail("Failed to create cache!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;

        entity TargetStatesCache is
            port(
                clk: in std_logic;
                address: in std_logic_vector(2 downto 0);
                data: in std_logic_vector(57 downto 0);
                we: in std_logic;
                ready: in std_logic;
                busy: out std_logic;
                value: out std_logic_vector(57 downto 0);
                value_en: out std_logic;
                lastAddress: out std_logic_vector(2 downto 0)
            );
        end TargetStatesCache;

        architecture Behavioral of TargetStatesCache is
            signal readValue: std_logic_vector(57 downto 0);
            signal readEnable: std_logic;
            signal writeValue: std_logic_vector(57 downto 0);
            signal writeEnable: std_logic;
            type Values_t is array (0 to 1) of std_logic_vector(31 downto 0);
            signal values: Values_t;
            signal currentValues: Values_t;
            signal memoryIndex: integer range 0 to 1;
            signal currentAddress: std_logic_vector(31 downto 0);
            signal addressBRAM: std_logic_vector(31 downto 0);
            signal weBRAM: std_logic;
            signal unsignedAddress: unsigned(31 downto 0);
            signal di: std_logic_vector(31 downto 0);
            signal valueBRAM: std_logic_vector(31 downto 0);
            type TargetStatesCacheInternalState_t is (Initial, WaitForNewData, WriteElement, WaitOneCycle, SetReadAddress, ReadElement, Error);
            signal internalState: TargetStatesCacheInternalState_t;
            signal maxAddress: unsigned(31 downto 0);
            component TargetStatesCacheEncoder is
                port(
                    in0: in std_logic_vector(57 downto 0);
                    in0en: in std_logic;
                    data0: out std_logic_vector(31 downto 0);
                    data1: out std_logic_vector(31 downto 0)
                );
            end component;
            component TargetStatesCacheDecoder is
                port(
                    data0: in std_logic_vector(31 downto 0);
                    data1: in std_logic_vector(31 downto 0);
                    out0: out std_logic_vector(57 downto 0);
                    out0en: out std_logic
                );
            end component;
            component TargetStatesCacheBRAM is
                port(
                    clk: in std_logic;
                    we: in std_logic;
                    addr: in std_logic_vector(31 downto 0);
                    di: in std_logic_vector(31 downto 0);
                    do: out std_logic_vector(31 downto 0)
                );
            end component;
        begin
            TargetStatesCacheEncoder_inst: component TargetStatesCacheEncoder port map (
                in0 => writeValue,
                in0en => writeEnable,
                data0 => values(0),
                data1 => values(1)
            );
            TargetStatesCacheDecoder_inst: component TargetStatesCacheDecoder port map (
                data0 => currentValues(0),
                data1 => currentValues(1),
                out0 => readValue,
                out0en => readEnable
            );
            TargetStatesCacheBRAM_inst: component TargetStatesCacheBRAM port map (
                clk => clk,
                we => weBRAM,
                addr => addressBRAM,
                di => di,
                do => valueBRAM
            );
            addressBRAM <= std_logic_vector(unsigned(currentAddress) + to_unsigned(memoryIndex, 32));
            unsignedAddress <= unsigned("00000000000000000000000000000" & address);
            lastAddress <= std_logic_vector(maxAddress);
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            writeValue <= (others => '0');
                            writeEnable <= '0';
                            currentValues <= (others => (others => '0'));
                            memoryIndex <= 0;
                            currentAddress <= (others => '0');
                            internalState <= WaitForNewData;
                            weBRAM <= '0';
                            maxAddress <= (others => '0');
                        when WaitForNewData =>
                            if (ready = '1' and we = '1') then
                                internalState <= WriteElement;
                                busy <= '1';
                                currentAddress <= std_logic_vector(unsignedAddress * 2);
                                writeValue <= data;
                                if (maxAddress < unsignedAddress) then
                                    maxAddress <= unsignedAddress;
                                end if;
                            elsif (ready = '1' and we = '0') then
                                internalState <= ReadElement;
                                busy <= '1';
                                currentAddress <= std_logic_vector(unsignedAddress * 2);
                            else
                                internalState <= WaitForNewData;
                                busy <= '0';
                            end if;
                            memoryIndex <= 0;
                            weBRAM <= '0';
                        when SetReadAddress =>
                            if (memoryIndex = 1) then
                                internalState <= WaitOneCycle;
                                busy <= '0';
                                value_en <= readEnable;
                                value <= readValue;
                            else
                                memoryIndex <= memoryIndex + 1;
                                internalState <= ReadElement;
                                busy <= '1';
                            end if;
                            weBRAM <= '0';
                        when ReadElement =>
                            internalState <= SetReadAddress;
                            currentValues(memoryIndex) <= valueBRAM;
                            busy <= '1';
                            weBRAM <= '0';
                        when WriteElement =>
                            if (memoryIndex = 1) then
                                internalState <= WaitOneCycle;
                                weBRAM <= '0';
                                busy <= '0';
                            else
                                memoryIndex <= memoryIndex + 1;
                                weBRAM <= '1';
                                busy <= '1';
                                di <= values(memoryIndex);
                            end if;
                        when WaitOneCycle =>
                            busy <= '0';
                            weBRAM <= '0';
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
        XCTAssertEqual(result.rawValue, expected)
    }

    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

}
