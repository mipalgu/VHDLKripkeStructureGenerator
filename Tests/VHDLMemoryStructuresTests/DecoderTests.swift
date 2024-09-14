// DecoderTests.swift
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

/// Tests for decoder creation.
final class DecoderTests: XCTestCase {

    /// Test decoder returns nil for invalid parameters.
    func testDecoderDetectsInvalidParameters() {
        XCTAssertNil(VHDLFile(decoderName: .targetStatesDecoder, numberOfElements: 0, elementSize: 3))
        XCTAssertNil(VHDLFile(decoderName: .targetStatesDecoder, numberOfElements: 3, elementSize: 0))
        XCTAssertNil(Entity(decoderName: .targetStatesDecoder, numberOfElements: 0, elementSize: 3))
        XCTAssertNil(Entity(decoderName: .targetStatesDecoder, numberOfElements: 3, elementSize: 0))
        XCTAssertNil(Architecture(decoderName: .targetStatesDecoder, numberOfElements: 0, elementSize: 3))
        XCTAssertNil(Architecture(decoderName: .targetStatesDecoder, numberOfElements: 3, elementSize: 0))
    }

    // swiftlint:disable function_body_length

    /// Test decoder creation.
    func testDecoder() {
        guard let result = VHDLFile(
            decoderName: .targetStatesDecoder, numberOfElements: 7, elementSize: 3
        ) else {
            XCTFail("Failed to create decoder!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity TargetStatesDecoder is
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
        end TargetStatesDecoder;

        architecture Behavioral of TargetStatesDecoder is
        \("    ")
        begin
            out0 <= data(31 downto 29);
            out0en <= data(28);
            out1 <= data(27 downto 25);
            out1en <= data(24);
            out2 <= data(23 downto 21);
            out2en <= data(20);
            out3 <= data(19 downto 17);
            out3en <= data(16);
            out4 <= data(15 downto 13);
            out4en <= data(12);
            out5 <= data(11 downto 9);
            out5en <= data(8);
            out6 <= data(7 downto 5);
            out6en <= data(4);
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
    }

    // swiftlint:enable function_body_length

    func testLargeDecoder() {
        guard let result = VHDLFile(
            decoderName: .targetStatesDecoder, numberOfElements: 1, elementSize: 58
        ) else {
            XCTFail("Failed to create decoder!")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use work.PrimitiveTypes.all;

        entity TargetStatesDecoder is
            port(
                data0: in std_logic_vector(31 downto 0);
                data1: in std_logic_vector(31 downto 0);
                out0: out std_logic_vector(57 downto 0);
                out0en: out std_logic
            );
        end TargetStatesDecoder;

        architecture Behavioral of TargetStatesDecoder is
        \("    ")
        begin
            out0 <= data0(31 downto 1) & data1(31 downto 5);
            out0en <= boolToStdLogic(data0(0) = '1' and data1(0) = '1');
        end Behavioral;

        """
        XCTAssertEqual(expected, result.rawValue)
    }

}

extension VariableName {

    static let targetStatesDecoder = VariableName(rawValue: "TargetStatesDecoder")!

    static let targetStatesEncoder = VariableName(rawValue: "TargetStatesEncoder")!

}
