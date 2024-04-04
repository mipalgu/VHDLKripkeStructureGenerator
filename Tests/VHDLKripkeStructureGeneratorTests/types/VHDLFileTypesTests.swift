// VHDLFileTypesTests.swift
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

/// Test class for `VHDLFile` type extensions.
final class VHDLFileTypesTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine, name: .M)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The raw VHDL for the ringlet runner of `machine`.
    let raw = """
    library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

    package MTypes is
        type ReadSnapshot_t is record
            x: std_logic;
            M_y2: std_logic;
            M_y: std_logic;
            M_STATE_Initial_initialX: std_logic;
            state: std_logic_vector(0 downto 0);
            executeOnEntry: boolean;
        end record ReadSnapshot_t;
        type WriteSnapshot_t is record
            x: std_logic;
            y2: std_logic;
            M_y: std_logic;
            M_STATE_Initial_initialX: std_logic;
            state: std_logic_vector(0 downto 0);
            nextState: std_logic_vector(0 downto 0);
            executeOnEntry: boolean;
        end record WriteSnapshot_t;
        type TotalSnapshot_t is record
            x: std_logic;
            y2: std_logic;
            M_x: std_logic;
            M_y2: std_logic;
            M_y2In: std_logic;
            M_y: std_logic;
            M_yIn: std_logic;
            M_STATE_Initial_initialX: std_logic;
            M_STATE_Initial_initialXIn: std_logic;
            currentStateIn: std_logic_vector(0 downto 0);
            currentStateOut: std_logic_vector(0 downto 0);
            previousRingletIn: std_logic_vector(0 downto 0);
            previousRingletOut: std_logic_vector(0 downto 0);
            internalStateIn: std_logic_vector(3 downto 0);
            internalStateOut: std_logic_vector(3 downto 0);
            targetStateIn: std_logic_vector(0 downto 0);
            targetStateOut: std_logic_vector(0 downto 0);
            reset: std_logic;
            goalInternalState: std_logic_vector(3 downto 0);
            finished: boolean;
            executeOnEntry: boolean;
            observed: boolean;
        end record TotalSnapshot_t;
        type Initial_ReadSnapshot_t is record
            x: std_logic;
            M_y2: std_logic;
            M_y: std_logic;
            M_STATE_Initial_initialX: std_logic;
            executeOnEntry: boolean;
        end record Initial_ReadSnapshot_t;
        type Initial_WriteSnapshot_t is record
            y2: std_logic;
            M_y: std_logic;
            M_STATE_Initial_initialX: std_logic;
            nextState: std_logic_vector(0 downto 0);
            executeOnEntry: boolean;
        end record Initial_WriteSnapshot_t;
        type Initial_Ringlet_t is record
            readSnapshot: Initial_ReadSnapshot_t;
            writeSnapshot: Initial_WriteSnapshot_t;
            observed: boolean;
        end record Initial_Ringlet_t;
        type Suspended_ReadSnapshot_t is record
            M_y2: std_logic;
            M_y: std_logic;
            M_STATE_Initial_initialX: std_logic;
            executeOnEntry: boolean;
        end record Suspended_ReadSnapshot_t;
        type Suspended_WriteSnapshot_t is record
            M_y2: std_logic;
            M_y: std_logic;
            M_STATE_Initial_initialX: std_logic;
            nextState: std_logic_vector(0 downto 0);
            executeOnEntry: boolean;
        end record Suspended_WriteSnapshot_t;
        type Suspended_Ringlet_t is record
            readSnapshot: Suspended_ReadSnapshot_t;
            writeSnapshot: Suspended_WriteSnapshot_t;
            observed: boolean;
        end record Suspended_Ringlet_t;
        type Initial_State_Execution_t is array (0 to 8) of std_logic_vector(0 to 17);
        type Suspended_State_Execution_t is array (0 to 0) of std_logic_vector(0 to 15);
        constant CheckTransition: std_logic_vector(3 downto 0) := "0000";
        constant Internal: std_logic_vector(3 downto 0) := "0001";
        constant NoOnEntry: std_logic_vector(3 downto 0) := "0010";
        constant OnEntry: std_logic_vector(3 downto 0) := "0011";
        constant OnExit: std_logic_vector(3 downto 0) := "0100";
        constant OnResume: std_logic_vector(3 downto 0) := "0101";
        constant OnSuspend: std_logic_vector(3 downto 0) := "0110";
        constant ReadSnapshot: std_logic_vector(3 downto 0) := "0111";
        constant WriteSnapshot: std_logic_vector(3 downto 0) := "1000";
        constant STATE_Initial: std_logic_vector(0 downto 0) := "0";
        constant STATE_Suspended: std_logic_vector(0 downto 0) := "1";
        constant COMMAND_NULL: std_logic_vector(1 downto 0) := "00";
        constant COMMAND_RESTART: std_logic_vector(1 downto 0) := "01";
        constant COMMAND_SUSPEND: std_logic_vector(1 downto 0) := "10";
        constant COMMAND_RESUME: std_logic_vector(1 downto 0) := "11";
    end package MTypes;

    """

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initialSuspensible
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
        machine.states[0].externalVariables = [.x, .y2]
    }

    /// Test package is created correctly.
    func testPackage() {
        let result = VHDLFile(typesFor: representation)
        // XCTAssertEqual(result!.rawValue, raw)
    }

}
