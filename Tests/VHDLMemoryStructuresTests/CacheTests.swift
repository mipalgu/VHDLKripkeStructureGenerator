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

        entity TargetStatesCache is
            port(
                clk: in std_logic;
                address: in std_logic_vector(3 downto 0);
                data: in std_logic_vector(2 downto 0);
                we: in std_logic;
                ready: in std_logic;
                busy: out std_logic;
                value: out std_logic_vector(2 downto 0);
                lastAddress: out std_logic_vector(3 downto 0)
            );
        end TargetStatesCache;

        architecture Behavioral of TargetStatesCache is
            type TargetStatesCacheCache_t is array (0 to 6) of std_logic_vector(2 downto 0);
            signal cache: TargetStatesCacheCache_t;
            signal cacheIndex: integer range 0 to 6;
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
            signal remainder: unsigned(3 downto 0);
            type TargetStatesCacheInternalState_t is (Initial, WaitForNewData, WriteElement, IncrementIndex, ResetEnables, Error);
            signal internalState: TargetStatesCacheInternalState_t;
        begin

        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

}
