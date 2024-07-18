// CacheMonitorTests.swift
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
@testable import VHDLMemoryStructures
import VHDLParsing
import XCTest

/// Tests for cache monitor.
final class CacheMonitorTests: XCTestCase {

    // swiftlint:disable force_unwrapping

    /// The cache to monitor.
    let cache = Entity(cacheName: VariableName(rawValue: "Cache")!, elementSize: 3, numberOfElements: 10)!

    // swiftlint:disable function_body_length
    // swiftlint:disable line_length

    /// Test monitor generation.
    func testMonitor() {
        guard let result = VHDLFile(
            cacheMonitorName: VariableName(rawValue: "CacheMonitor")!, numberOfMembers: 2, cache: cache
        ) else {
            XCTFail("Failed to create cache monitor!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity CacheMonitor is
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
                value: out std_logic_vector(2 downto 0);
                value_en: out std_logic;
                busy: out std_logic;
                lastAddress: out std_logic_vector(3 downto 0)
            );
        end CacheMonitor;

        architecture Behavioral of CacheMonitor is
            type CacheMonitorInternalState_t is (Initial, ChooseAccess, WaitWhileBusy);
            signal address: std_logic_vector(3 downto 0);
            signal data: std_logic_vector(2 downto 0);
            signal we: std_logic;
            signal ready: std_logic;
            signal enables: std_logic_vector(1 downto 0);
            signal lastEnabled: std_logic_vector(1 downto 0);
            signal internalState: CacheMonitorInternalState_t := Initial;
            component Cache is
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
            end component;
        begin
            cache_inst: component Cache port map (
                clk => clk,
                address => address,
                data => data,
                we => we,
                ready => ready,
                busy => busy,
                value => value,
                value_en => value_en,
                lastAddress => lastAddress
            );
            en0 <= enables(0);
            en1 <= enables(1);
            address <= address0 when enables(0) = '1' else address1 when enables(1) = '1' else (others => '0');
            data <= data0 when enables(0) = '1' else data1 when enables(1) = '1' else (others => '0');
            we <= we0 when enables(0) = '1' else we1 when enables(1) = '1' else '0';
            ready <= ready0 when enables(0) = '1' else ready1 when enables(1) = '1' else '0';
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            enables <= "01";
                            lastEnabled <= "01";
                            internalState <= WaitWhileBusy;
                        when WaitWhileBusy =>
                            if (ready /= '1') then
                                internalState <= ChooseAccess;
                                enables <= (others => '0');
                                lastEnabled <= enables;
                            end if;
                        when ChooseAccess =>
                            if (lastEnabled = "10") then
                                enables <= "01";
                            else
                                enables <= lastEnabled(0 downto 0) & "0";
                            end if;
                            internalState <= WaitWhileBusy;
                    end case;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

    // swiftlint:enable line_length
    // swiftlint:enable function_body_length

    // swiftlint:enable force_unwrapping

}
