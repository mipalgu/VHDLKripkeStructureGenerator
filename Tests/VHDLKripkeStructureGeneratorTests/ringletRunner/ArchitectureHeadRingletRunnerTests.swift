// ArchitectureHeadRingletRunnerTests.swift
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
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for `ArchitectureHead` ringlet runner extensions.
final class ArchitectureHeadRingletRunnerTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The raw VHDL for the ringlet runner of `machine`.
    let raw = """
    constant ReadSnapshot: std_logic_vector(2 downto 0) := "101";
    constant WriteSnapshot: std_logic_vector(2 downto 0) := "110";
    signal machine: TotalSnapshot_t := (
        x => '0',
        M_x => '0',
        y2 => '0',
        M_y2 => '0',
        M_y2In => '0',
        M_y => '0',
        M_yIn => '0',
        M_STATE_Initial_initialX => '0',
        M_STATE_Initial_initialXIn => '0',
        currentStateIn => (others => '0'),
        currentStateOut => (others => '0'),
        previousRingletIn => (others => '0'),
        previousRingletOut => (others => '0'),
        internalStateIn => ReadSnapshot,
        internalStateOut => ReadSnapshot,
        targetStateIn => (others => '0'),
        targetStateOut => (others => '0'),
        reset => '0',
        goalInternalState => WriteSnapshot,
        finished => true,
        executeOnEntry => true,
        observed => false
    );
    signal tracker: std_logic_vector(1 downto 0) := "00";
    constant WaitForStart: std_logic_vector(1 downto 0) := "00";
    constant Executing: std_logic_vector(1 downto 0) := "01";
    constant WaitForMachineStart: std_logic_vector(1 downto 0) := "10";
    constant WaitForFinish: std_logic_vector(1 downto 0) := "11";
    signal currentState: std_logic_vector(0 downto 0) := "0";
    component MMachineRunner is
    port(
        clk: in std_logic;
        internalStateIn: in std_logic_vector(2 downto 0);
        internalStateOut: out std_logic_vector(2 downto 0);
        currentStateIn: in std_logic_vector(0 downto 0);
        currentStateOut: out std_logic_vector(0 downto 0);
        previousRingletIn: in std_logic_vector(0 downto 0);
        previousRingletOut: out std_logic_vector(0 downto 0);
        targetStateIn: in std_logic_vector(0 downto 0);
        targetStateOut: out std_logic_vector(0 downto 0);
        x: in std_logic;
        y2: out std_logic;
        M_x: out std_logic;
        M_y2: out std_logic;
        M_y2In: in std_logic;
        M_y: out std_logic;
        M_yIn: in std_logic;
        M_STATE_Initial_initialX: out std_logic;
        M_STATE_Initial_initialXIn: in std_logic;
        reset: in std_logic;
        goalInternalState: in std_logic_vector(2 downto 0);
        finished: out boolean := true
    );
    end component;
    """

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initial(path: URL(fileURLWithPath: "/path/to/M.machine", isDirectory: true))
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
    }

    /// Test that the ringlet runner init creates the correct head.
    func testInit() {
        guard let expected = ArchitectureHead(rawValue: raw) else {
            XCTFail("Failed to create expected value.")
            return
        }
        let result = ArchitectureHead(ringletRunnerFor: representation)
        XCTAssertEqual(result, expected)
        result!.rawValue.components(separatedBy: .newlines).forEach {
            print($0)
        }
        guard
            case .definition(let definition) = result!.statements[2],
            case .signal(let signal) = definition,
            let defaultValue = signal.defaultValue,
            case .literal(let literal) = defaultValue,
            case .vector(let vector) = literal,
            case .indexed(let indexed) = vector,
            case .definition(let def) = expected.statements[2],
            case .signal(let sig) = def,
            let value = sig.defaultValue,
            case .literal(let lit) = value,
            case .vector(let vec) = lit,
            case .indexed(let ind) = vec
        else {
            XCTFail("Failed to find default value.")
            return
        }
        indexed.values.indices.forEach {
            XCTAssertEqual(indexed.values[$0], ind.values[$0])
        }
    }

}
