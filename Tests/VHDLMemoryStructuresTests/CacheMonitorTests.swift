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
import Utilities
@testable import VHDLMemoryStructures
import VHDLParsing
import XCTest

/// Test class for cache monitor implementation.
final class CacheMonitorTests: XCTestCase {

    /// Test monitor creation.
    func testGeneration() {
        guard let result = VHDLFile(
            cacheMonitorName: .targetStatesCacheMonitor,
            cacheName: .targetStatesCache,
            elementSize: 3,
            numberOfElements: 12,
            selectors: 3
        ) else {
            XCTFail("Failed to create monitor!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;

        entity TargetStatesCacheMonitor is
            port(
                clk: in std_logic;
                address0: in std_logic_vector(3 downto 0);
                data0: in std_logic_vector(2 downto 0);
                we0: in std_logic;
                ready0: in std_logic;
                busy0: out std_logic;
                value0: out std_logic_vector(2 downto 0);
                value_en0: out std_logic;
                address1: in std_logic_vector(3 downto 0);
                data1: in std_logic_vector(2 downto 0);
                we1: in std_logic;
                ready1: in std_logic;
                busy1: out std_logic;
                value1: out std_logic_vector(2 downto 0);
                value_en1: out std_logic;
                address2: in std_logic_vector(3 downto 0);
                data2: in std_logic_vector(2 downto 0);
                we2: in std_logic;
                ready2: in std_logic;
                busy2: out std_logic;
                value2: out std_logic_vector(2 downto 0);
                value_en2: out std_logic;
                lastAddress: out std_logic_vector(3 downto 0)
            );
        end TargetStatesCacheMonitor;

        architecture Behavioral of TargetStatesCacheMonitor is
            signal address: std_logic_vector(3 downto 0);
            signal data: std_logic_vector(2 downto 0);
            signal we: std_logic;
            signal ready: std_logic;
            signal busy: std_logic;
            signal value: std_logic_vector(2 downto 0);
            signal value_en: std_logic;
            signal lastValue0: std_logic_vector(2 downto 0);
            signal lastValue_en0: std_logic;
            signal selector0_en: std_logic := '0';
            signal lastValue1: std_logic_vector(2 downto 0);
            signal lastValue_en1: std_logic;
            signal selector1_en: std_logic := '0';
            signal lastValue2: std_logic_vector(2 downto 0);
            signal lastValue_en2: std_logic;
            signal selector2_en: std_logic := '0';
            type TargetStatesCacheMonitor_InternalState_t is (Initial, CheckSelector0, CheckSelector1, CheckSelector2, WaitForCacheStart, WaitForCacheEnd);
            signal internalState: TargetStatesCacheMonitor_InternalState_t := Initial;
            signal nextState: TargetStatesCacheMonitor_InternalState_t := CheckSelector0;
            component TargetStatesCache is
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
            TargetStatesCache_inst: component TargetStatesCache port map (
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
            address <= address0 when selector0_en = '1' else address1 when selector1_en = '1' else address2;
            data <= data0 when selector0_en = '1' else data1 when selector1_en = '1' else data2;
            we <= we0 when selector0_en = '1' else we1 when selector1_en = '1' else we2;
            ready <= ready0 when selector0_en = '1' else ready1 when selector1_en = '1' else ready2;
            busy0 <= busy when selector0_en = '1' else '1';
            value0 <= value when selector0_en = '1' else lastValue0;
            value_en0 <= value_en when selector0_en = '1' else lastValue_en0;
            busy1 <= busy when selector1_en = '1' else '1';
            value1 <= value when selector1_en = '1' else lastValue1;
            value_en1 <= value_en when selector1_en = '1' else lastValue_en1;
            busy2 <= busy when selector2_en = '1' else '1';
            value2 <= value when selector2_en = '1' else lastValue2;
            value_en2 <= value_en when selector2_en = '1' else lastValue_en2;
            process(clk)
            begin
                if (rising_edge(clk)) then
                    case internalState is
                        when Initial =>
                            selector0_en <= '0';
                            selector1_en <= '0';
                            selector2_en <= '0';
                            internalState <= CheckSelector0;
                            nextState <= CheckSelector0;
                        when CheckSelector0 =>
                            if (ready0 = '1') then
                                selector0_en <= '1';
                                nextState <= CheckSelector1;
                                if (busy = '1') then
                                    internalState <= WaitForCacheStart;
                                else
                                    internalState <= WaitForCacheEnd;
                                end if;
                            else
                                selector0_en <= '0';
                                internalState <= CheckSelector1;
                            end if;
                            selector1_en <= '0';
                            selector2_en <= '0';
                        when CheckSelector1 =>
                            if (read1 = '1') then
                                selector1_en <= '1';
                                nextState <= CheckSelector2;
                                if (busy = '1') then
                                    internalState <= WaitForCacheStart;
                                else
                                    internalState <= WaitForCacheEnd;
                                end if;
                            end if;
                            selector0_en <= '0';
                            selector2_en <= '0';
                        when CheckSelector2 =>
                            if (read2 = '1') then
                                selector2_en <= '1';
                                nextState <= CheckSelector0;
                                if (busy = '1') then
                                    internalState <= WaitForCacheStart;
                                else
                                    internalState <= WaitForCacheEnd;
                                end if;
                            end if;
                            selector0_en <= '0';
                            selector1_en <= '0';
                        when WaitForCacheStart =>
                            if (busy = '1') then
                                internalState <= WaitForCacheEnd;
                            else
                                internalState <= WaitForCacheStart;
                            end if;
                        when WaitForCacheEnd =>
                            if (busy = '0') then
                                internalState <= nextState;
                            else
                                internalState <= WaitForCacheEnd;
                            end if;
                    end cast;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

}
