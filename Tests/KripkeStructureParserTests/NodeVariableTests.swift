// NodeVariableTests.swift
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

@testable import KripkeStructureParser
import TestUtils
import VHDLParsing
import XCTest

/// Test class for ``NodeVariable``.
final class NodeVariableTests: XCTestCase {

    /// The declaration of a record member.
    let declaration0 = RecordTypeDeclaration(name: .x, type: .signal(type: .stdLogic))

    /// The declaration of a record member.
    let declaration1 = RecordTypeDeclaration(name: .y, type: .signal(type: .bit))

    /// The declaration of a record member.
    let declaration2 = RecordTypeDeclaration(name: .z, type: .signal(type: .integer))

    /// Test init sets stored properties correctly.
    func testInit() {
        let variable = NodeVariable(data: declaration0, type: .write)
        XCTAssertEqual(variable.data, declaration0)
        XCTAssertEqual(variable.type, .write)
    }

    /// Test that comparable sorts the variables by type first.
    func testComparableConformance() {
        let variable0 = NodeVariable(data: declaration0, type: .write)
        let variable1 = NodeVariable(data: declaration1, type: .read)
        let variable2 = NodeVariable(data: declaration2, type: .write)
        let variable3 = NodeVariable(data: declaration0, type: .read)
        let variable4 = NodeVariable(data: declaration1, type: .write)
        let variable5 = NodeVariable(data: declaration2, type: .read)
        let variables = [variable0, variable1, variable2, variable3, variable4, variable5]
        let sorted = variables.sorted()
        XCTAssertEqual(sorted, [variable3, variable1, variable5, variable0, variable4, variable2])
    }

}
