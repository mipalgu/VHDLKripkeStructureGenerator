// VHDLFileStateGeneratorTests.swift
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

/// Test class for `VHDLFile` state generator extensions.
final class VHDLFileStateGeneratorTests: XCTestCase {

    // swiftlint:disable implicitly_unwrapped_optional

    /// A machine to use for testing.
    var machine: Machine!

    /// The equivalent representation for `machine`.
    var representation: MachineRepresentation! {
        MachineRepresentation(machine: machine)
    }

    // swiftlint:enable implicitly_unwrapped_optional

    /// The ringlet assignment.
    let ringletAssignment = "ringlet <= (readSnapshot => (x => readSnapshot.x, M_y2 => readSnapshot.M_y2," +
        " M_y => readSnapshot.M_y, M_STATE_Initial_initialX => readSnapshot.M_STATE_Initial_initialX," +
            " executeOnEntry => readSnapshot.executeOnEntry), writeSnapshot => (y2 =>" +
            " writeSnapshot.y2, M_y => writeSnapshot.M_y, M_STATE_Initial_initialX =>" +
            " writeSnapshot.M_STATE_Initial_initialX, nextState => writeSnapshot.nextState, executeOnEntry" +
            " => writeSnapshot.executeOnEntry), observed => true);"

    /// The pendingState assignment.
    let pendingState = "pendingState <= writeSnapshot.nextState & writeSnapshot.y2 & writeSnapshot.M_y" +
        " & writeSnapshot.M_STATE_Initial_initialX & boolToStdLogic(writeSnapshot.executeOnEntry)" +
        " & '1';"

    /// The raw VHDL for the ringlet runner of `machine`.
    var raw: String {
        """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use work.MTypes.all;
        use work.PrimitiveTypes.all;

        entity InitialKripkeGenerator is
            port(
                clk: in std_logic;
                readSnapshot: in ReadSnapshot_t;
                writeSnapshot: in WriteSnapshot_t;
                ringlet: out Initial_Ringlet_t;
                pendingState: out std_logic_vector(5 downto 0)
            );
        end InitialKripkeGenerator;

        architecture Behavioral of InitialKripkeGenerator is
        \(String.tab)
        begin
            process(clk)
            begin
                if (rising_edge(clk)) then
                    \(ringletAssignment)
                    \(pendingState)
                end if;
            end process;
        end Behavioral;

        """
    }

    /// Initialise the machine before every test.
    override func setUp() {
        machine = Machine.initial(path: URL(fileURLWithPath: "/path/to/M.machine", isDirectory: true))
        machine.externalSignals = [
            PortSignal(type: .stdLogic, name: .x, mode: .input),
            PortSignal(type: .stdLogic, name: .y2, mode: .output)
        ]
        machine.machineSignals = [LocalSignal(type: .stdLogic, name: .y)]
        machine.states[0].signals = [LocalSignal(type: .stdLogic, name: .initialX)]
        machine.states[0].externalVariables = [.x, .y2]
    }

    /// Verify that the state generator is created successfully.
    func testStateGenerator() {
        let result = VHDLFile(stateGeneratorFor: machine.states[0], in: representation)
        XCTAssertEqual(result?.rawValue, raw)
    }

}
