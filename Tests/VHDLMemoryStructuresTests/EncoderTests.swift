// EncoderTests.swift
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

@testable import VHDLMemoryStructures
import VHDLParsing
import XCTest

/// Test class for encoder creation.
final class EncoderTests: XCTestCase {

    /// Test encoder returns nil for invalid parameters.
    func testEncoderDetectsInvalidParameters() {
        XCTAssertNil(VHDLFile(encoderName: .targetStatesDecoder, numberOfElements: 0, elementSize: 3))
        XCTAssertNil(VHDLFile(encoderName: .targetStatesDecoder, numberOfElements: 3, elementSize: 0))
        XCTAssertNil(Entity(encoderName: .targetStatesDecoder, numberOfElements: 0, elementSize: 3))
        XCTAssertNil(Entity(encoderName: .targetStatesDecoder, numberOfElements: 3, elementSize: 0))
        XCTAssertNil(Architecture(encoderName: .targetStatesDecoder, numberOfElements: 0, elementSize: 3))
        XCTAssertNil(Architecture(encoderName: .targetStatesDecoder, numberOfElements: 3, elementSize: 0))
    }

    // swiftlint:disable line_length

    /// Test encoder creation.
    func testEncoderCreation() {
        guard let result = VHDLFile(
            encoderName: .targetStatesEncoder, numberOfElements: 7, elementSize: 3
        ) else {
            XCTFail("Failed to create encoder!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity TargetStatesEncoder is
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
        end TargetStatesEncoder;

        architecture Behavioral of TargetStatesEncoder is
        \("    ")
        begin
            data <= in0 & in0en & in1 & in1en & in2 & in2en & in3 & in3en & in4 & in4en & in5 & in5en & in6 & in6en & "0000";
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
    }

    /// Test encoder creation.
    func testEncoderCreationWithNoPadding() {
        guard let result = VHDLFile(
            encoderName: .targetStatesEncoder, numberOfElements: 8, elementSize: 3
        ) else {
            XCTFail("Failed to create encoder!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity TargetStatesEncoder is
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
                in7: in std_logic_vector(2 downto 0);
                in7en: in std_logic;
                data: out std_logic_vector(31 downto 0)
            );
        end TargetStatesEncoder;

        architecture Behavioral of TargetStatesEncoder is
        \("    ")
        begin
            data <= in0 & in0en & in1 & in1en & in2 & in2en & in3 & in3en & in4 & in4en & in5 & in5en & in6 & in6en & in7 & in7en;
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
    }

    // swiftlint:enable line_length

    func testLargeEncoderCreation() {
        guard let result = VHDLFile(
            encoderName: .targetStatesEncoder, numberOfElements: 1, elementSize: 58
        ) else {
            XCTFail("Failed to create encoder!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity TargetStatesEncoder is
            port(
                in0: in std_logic_vector(57 downto 0);
                in0en: in std_logic;
                data0: out std_logic_vector(31 downto 0);
                data1: out std_logic_vector(31 downto 0)
            );
        end TargetStatesEncoder;

        architecture Behavioral of TargetStatesEncoder is
        \("    ")
        begin
            data0 <= in0(57 downto 27) & in0en;
            data1 <= in0(26 downto 0) & "0000" & in0en;
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
        XCTAssertNil(VHDLFile(encoderName: .targetStatesEncoder, numberOfElements: 2, elementSize: 58))
    }

}
