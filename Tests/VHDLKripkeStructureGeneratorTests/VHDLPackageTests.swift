// PackageTests.swift
// VHDLKripkeStructureGenerator
// 
// Created by Morgan McColl.
// Copyright © 2023 Morgan McColl. All rights reserved.
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
// 

@testable import VHDLKripkeStructureGenerator
import VHDLParsing
import XCTest

/// Test class for ``Package`` extensions.
final class VHDLPackageTests: XCTestCase {

    /// Test the `PrimitiveTypes` package is defined correctly.
    func testPrimitiveTypesPackage() {
        // swiftlint:disable line_length
        let expected = """
        package PrimitiveTypes is
            type stdLogicTypes_t is array (0 to 8) of std_logic;
            constant stdLogicTypes: stdLogicTypes_t := (0 => 'U', 1 => 'X', 2 => '0', 3 => '1', 4 => 'Z', 5 => 'W', 6 => 'L', 7 => 'H', 8 => '-');
            type BitTypes_t is array (0 to 1) of bit;
            constant bitTypes: BitTypes_t := (0 => '0', 1 => '1');
            type BooleanTypes_t is array (0 to 1) of boolean;
            constant booleanTypes: BooleanTypes_t := (0 => false, 1 => true);
            function boolToStdLogic(value: boolean) return std_logic;
            function stdLogicToBool(value: std_logic) return boolean;
            function stdLogicEncoded(value: std_logic) return std_logic_vector(1 downto 0);
            function stdULogicEncoded(value: std_ulogic) return std_logic_vector(1 downto 0);
        end package PrimitiveTypes;
        """
        // swiftlint:enable line_length
        XCTAssertEqual(VHDLPackage.primitiveTypes.rawValue, expected)
    }

}
