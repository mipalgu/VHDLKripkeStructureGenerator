// ArrangementGeneratorTests.swift
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
@testable import VHDLArrangementGenerator
import VHDLMachines
import VHDLParsing
import XCTest

final class ArrangementGeneratorTests: XCTestCase {

    func testRawValue() {
        guard let result = VHDLFile(
            generatorFor: Arrangement.pingPongRepresentation,
            machines: [.pingMachine: MachineRepresentation(machine: .pingMachine, name: .pingMachine)!]
        ) else {
            XCTFail("Failed to create VHDLFile.")
            return
        }
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;

        entity PingPongGenerator is
            port(
                clk: in std_logic;
                address: in std_logic_vector(9 downto 0);
                read: in std_logic;
                ready: in std_logic;
                data: out std_logic_vector(31 downto 0);
                finished: out std_logic
            );
        end PingPongGenerator;

        architecture Behavioral of PingPongGenerator is
            signal ready: std_logic;
            signal busy: std_logic;
            signal PingPong_READ_ping: std_logic;
            signal PingPong_READ_pong: std_logic;
            signal PingPong_WRITE_ping: std_logic;
            signal PingPong_WRITE_pong: std_logic;
            signal PingPong_READ_PingMachine_state: std_logic_vector(1 downto 0);
            signal PingPong_READ_PingMachine_executeOnEntry: std_logic;
            signal PingPong_READ_PingMachine_pong: std_logic;
            signal PingPong_WRITE_PingMachine_state: std_logic_vector(1 downto 0);
            signal PingPong_WRITE_PingMachine_executeOnEntry: std_logic;
            component PingPongArrangementRunner is
                port(
                    clk: in std_logic;
                    ready: in std_logic;
                    PingPong_READ_ping: in std_logic;
                    PingPong_READ_pong: in std_logic;
                    PingPong_WRITE_PingMachine_executeOnEntry: out std_logic;
                    PingPong_WRITE_PingMachine_state: out std_logic_vector(1 downto 0);
                    PingPong_READ_PingMachine_pong: in std_logic;
                    PingPong_READ_PingMachine_executeOnEntry: in std_logic;
                    PingPong_READ_PingMachine_state: in std_logic_vector(1 downto 0);
                    PingPong_WRITE_ping: out std_logic;
                    PingPong_WRITE_pong: out std_logic;
                    busy: out std_logic;
                );
            end component;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

}
