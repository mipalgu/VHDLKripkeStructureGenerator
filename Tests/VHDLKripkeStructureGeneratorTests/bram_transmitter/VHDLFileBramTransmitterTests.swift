// VHDLFileBramTransmitterTests.swift
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

@testable import VHDLKripkeStructureGenerator
import VHDLMachines
import VHDLParsing
import TestUtils
import XCTest

final class VHDLFileBramTransmitterTests: XCTestCase {

    func testRawValue() {
        guard let representation = MachineRepresentation(machine: .pingMachine, name: .pingMachine) else {
            XCTFail("Failed to create representation")
            return
        }
        let result = VHDLFile(bramTransmitterFor: representation)
        let expected = """
        library IEEE;
        use IEEE.std_logic_1164.all;
        use IEEE.numeric_std.all;

        entity BRAMTransmitter is
            port(
                clk: in std_logic;
                startTransmission: in std_logic;
                reset: in std_logic;
                tx: out std_logic;
                rdy: out std_logic;
                finishedTx: out std_logic;
                finishedGeneration: out std_logic
            );
        end BRAMTransmitter;

        architecture Behavioral of BRAMTransmitter is
            signal address: std_logic_vector(31 downto 0);
            signal read: std_logic;
            signal ready: std_logic;
            signal data: std_logic_vector(31 downto 0);
            signal finished: std_logic;
            signal word: std_logic_vector(0 to 7);
            signal txBusy: std_logic;
            signal txReady: std_logic;
            signal baudPulse: std_logic;
            signal currentData: std_logic_vector(31 downto 0);
            signal currentAddress: unsigned(31 downto 0) := x"00000000";
            signal currentByte: integer range -1 to 3 := 3;
            signal txTrailer: std_logic;
            type BRAMTransmitter_CurrentState_t is (Initial, WaitForFinish, StartReadAddress, ReadAddress, WaitForButton, WaitForFree, WaitForBusy, FinishedTransmission);
            signal currentState: BRAMTransmitter_CurrentState_t := Initial;
            component BRAMInterface is
                port(
                    clk: in std_logic;
                    address: in std_logic_vector(31 downto 0);
                    read: in std_logic;
                    ready: in std_logic;
                    data: out std_logic_vector(31 downto 0);
                    finished: out std_logic
                );
            end component;
            component UARTTransmitter is
                port(
                    clk: in std_logic;
                    baudPulse: in std_logic;
                    word: in std_logic_vector(0 to 7);
                    ready: in std_logic;
                    tx: out std_logic;
                    busy: out std_logic
                );
            end component;
            component BaudGenerator is
                port(
                    clk: in std_logic;
                    pulse: out std_logic
                );
            end component;
        begin
            address <= std_logic_vector(currentAddress);
            finishedGeneration <= finished;
            bram_inst: component BRAMInterface port map (
                clk => clk,
                address => address,
                read => read,
                ready => ready,
                data => data,
                finished => finished
            );
            uart_inst: component UARTTransmitter port map (
                clk => clk,
                baudPulse => baudPulse,
                word => word,
                ready => txReady,
                tx => tx,
                busy => txBusy
            );
            baud_inst: component BaudGenerator port map (
                clk => clk,
                pulse => baudPulse
            );
            process(clk)
            begin
                if (rising_edge(clk)) then
                    if (reset = '1') then
                        currentState <= Initial;
                        rdy <= '0';
                        finishedTx <= '0';
                        txTrailer <= '0';
                    elsif (currentState = Initial) then
                        currentData <= (others => '0');
                        currentAddress <= (others => '0');
                        currentByte <= 3;
                        read <= '0';
                        ready <= '0';
                        word <= (others => '0');
                        currentState <= WaitForFinish;
                        finishedTx <= '0';
                        rdy <= '0';
                        txTrailer <= '0';
                    elsif (currentState = WaitForFinish) then
                        currentData <= (others => '0');
                        currentAddress <= (others => '0');
                        currentByte <= 3;
                        word <= (others => '0');
                        finishedTx <= '0';
                        if (finished = '1') then
                            currentState <= StartReadAddress;
                            read <= '1';
                            ready <= '1';
                            rdy <= '1';
                        else
                            read <= '0';
                            ready <= '0';
                            rdy <= '0';
                        end if;
                    elsif (finished = '1') then
                        rdy <= '1';
                        case currentState is
                            when StartReadAddress =>
                                read <= '1';
                                ready <= '1';
                                currentState <= ReadAddress;
                                finishedTx <= '0';
                            when ReadAddress =>
                                read <= '0';
                                ready <= '0';
                                finishedTx <= '0';
                                if (data(0) = '1') then
                                    currentData <= data;
                                    currentState <= WaitForButton;
                                elsif (txTrailer = '1') then
                                    currentData <= data;
                                    currentState <= FinishedTransmission;
                                else
                                    currentData <= (0 => '0', others => '1');
                                    txTrailer <= '1';
                                    currentState <= WaitForButton;
                                end if;
                            when WaitForButton =>
                                read <= '0';
                                ready <= '0';
                                finishedTx <= '0';
                                if (startTransmission = '1') then
                                    currentState <= WaitForFree;
                                end if;
                            when WaitForFree =>
                                if (currentByte = -1) then
                                    read <= '1';
                                    ready <= '1';
                                    currentState <= StartReadAddress;
                                    currentAddress <= currentAddress + 1;
                                    currentByte <= 3;
                                else
                                    read <= '0';
                                    ready <= '0';
                                    if (txBusy = '0') then
                                        word <= currentData(currentByte * 8 + 7 downto currentByte * 8);
                                        txReady <= '1';
                                        currentState <= WaitForBusy;
                                    end if;
                                end if;
                                finishedTx <= '0';
                            when WaitForBusy =>
                                read <= '0';
                                ready <= '0';
                                word <= currentData(currentByte * 8 + 7 downto currentByte * 8);
                                finishedTx <= '0';
                                if (txBusy = '1') then
                                    txReady <= '0';
                                    currentState <= WaitForFree;
                                    currentByte <= currentByte - 1;
                                else
                                    txReady <= '1';
                                end if;
                            when FinishedTransmission =>
                                txReady <= '0';
                                finishedTx <= '1';
                            when others =>
                                currentState <= Initial;
                        end case;
                    else
                        rdy <= '0';
                        finishedTx <= '0';
                    end if;
                end if;
            end process;
        end Behavioral;

        """
        XCTAssertEqual(result.rawValue, expected)
    }

}
