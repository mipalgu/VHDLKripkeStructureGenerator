// TargetStateEncoderTests.swift
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

/// Test extension for `TargetStatesEncoder`.
final class TargetStateEncoderTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A test machine.
    let representation: MachineRepresentation! = MachineRepresentation(
        machine: .pingMachine, name: .pingMachine
    )

    // swiftlint:enable implicitly_unwrapped_optional

    /// Test generation of encoder.
    func testGeneration() {
        guard let result = VHDLFile(targetStatesEncoderFor: representation) else {
            XCTFail("Failed to generate result!")
            return
        }
        // swiftlint:disable line_length
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity TargetStatesEncoder is
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
        end TargetStatesEncoder;

        architecture Behavioral of TargetStatesEncoder is
        \("    ")
        begin
            data <= state0 & state0en & state1 & state1en & state2 & state2en & state3 & state3en & state4 & state4en & state5 & state5en & state6 & state6en & "000" & state0en;
        end Behavioral;

        """
        // swiftlint:enable line_length
        XCTAssertEqual(result.rawValue, expected, "\(result.rawValue.difference(from: expected))")
    }

}
