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
            type TargetStatesCacheCache_t is array (0 to 6) of std_logic_vector(2 downto 0);
            signal cache: TargetStatesCacheCache_t;
            signal cacheIndex: integer range 0 to 6;
            signal memoryIndex: integer range 0 to 2;
            signal genIndex: std_logic_vector(31 downto 0);
            signal di: std_logic_vector(31 downto 0);
            signal index: std_logic_vector(31 downto 0);
            signal weBRAM: std_logic;
            signal currentValue: std_logic_vector(31 downto 0);
            signal memoryAddress: std_logic_vector(31 downto 0);
            type TargetStatesCacheEnables_t is array (0 to 6) of std_logic;
            signal enables: TargetStatesCacheEnables_t;
            signal readEnables: TargetStatesCacheEnables_t;
            signal readCache: TargetStatesCacheCache_t;
            signal unsignedAddress: unsigned(3 downto 0);
            constant denominator: unsigned(3 downto 0) := "0111";
            signal result: unsigned(3 downto 0);
            signal remainder: unsigned(3 downto 0);
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
                    in4: in std_logic_vector(2 downto 0);
                    in4en: in std_logic;
                    in5: in std_logic_vector(2 downto 0);
                    in5en: in std_logic;
                    in6: in std_logic_vector(2 downto 0);
                    in6en: in std_logic;
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
                    out3en: out std_logic;
                    out4: out std_logic_vector(2 downto 0);
                    out4en: out std_logic;
                    out5: out std_logic_vector(2 downto 0);
                    out5en: out std_logic;
                    out6: out std_logic_vector(2 downto 0);
                    out6en: out std_logic
                );
            end component;
            component TargetStatesCacheDivider is
                port(
                    clk: in std_logic;
                    numerator: in unsigned(3 downto 0);
                    denominator: in unsigned(3 downto 0);
                    result: out unsigned(3 downto 0);
                    remainder: out unsigned(3 downto 0)
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
                in4 => cache(4),
                in4en => enables(4),
                in5 => cache(5),
                in5en => enables(5),
                in6 => cache(6),
                in6en => enables(6),
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
                out3en => readEnables(3),
                out4 => readCache(4),
                out4en => readEnables(4),
                out5 => readCache(5),
                out5en => readEnables(5),
                out6 => readCache(6),
                out6en => readEnables(6)
            );
            TargetStatesCacheDivider_inst: component TargetStatesCacheDivider port map (
                clk => clk,
                numerator => unsignedAddress,
                denominator => denominator,
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
            unsignedAddress <= unsigned(address);
            memoryAddress <= "0000000000000000000000000000" & std_logic_vector(result);
            value <= readCache(to_integer(remainder));
            value_en <= readEnables(to_integer(remainder));
            index <= memoryAddress when ready = '1' and we /= '1' and internalState = WaitForNewData else genIndex;
            genIndex <= std_logic_vector(to_unsigned(memoryIndex, 32));
            lastAddress <= std_logic_vector(unsignedLastAddress);
            currentIndex <= to_unsigned(memoryIndex, 4) * denominator + to_unsigned(cacheIndex, 4);
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
                            if (memoryIndex = 2) then
                                internalState <= Error;
                                weBRAM <= '0';
                            elsif (cacheIndex = 6) then
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

    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

}
