// VHDLFIleUARTTransmitterTests.swift
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
import VHDLParsing
import XCTest

/// Test class for `VHDLFile` `uart_transmitter` extensions.
final class VHDLFileUARTTransmitterTests: XCTestCase {

    /// The expected `UARTTransmitter` file.
    let expected = """
    library IEEE;
    use IEEE.std_logic_1164.all;

    entity UARTTransmitter is
        port(
            clk: in std_logic;
            baudPulse: in std_logic;
            word: in std_logic_vector(0 to 7);
            ready: in std_logic;
            tx: out std_logic;
            busy: out std_logic
        );
    end UARTTransmitter;

    architecture Behavioral of UARTTransmitter is
        signal data: std_logic_vector(0 to 7) := x"00";
        signal bitCount: integer range 0 to 7 := 7;
        signal currentState: std_logic_vector(3 downto 0) := x"0";
        constant Initial: std_logic_vector(3 downto 0) := x"0";
        constant WaitForReady: std_logic_vector(3 downto 0) := x"1";
        constant WaitForStopLow: std_logic_vector(3 downto 0) := x"2";
        constant WaitForStopPulse: std_logic_vector(3 downto 0) := x"3";
        constant WaitForDataLow: std_logic_vector(3 downto 0) := x"4";
        constant WaitForDataHigh: std_logic_vector(3 downto 0) := x"5";
        constant SentDataBit: std_logic_vector(3 downto 0) := x"6";
        constant WaitForBitPulse: std_logic_vector(3 downto 0) := x"7";
    begin
        process(clk)
        begin
            if (rising_edge(clk)) then
                case currentState is
                    when Initial =>
                        busy <= '0';
                        tx <= '1';
                        bitCount <= 7;
                        currentState <= WaitForReady;
                    when WaitForReady =>
                        if (ready = '1') then
                            busy <= '1';
                            data <= word;
                            tx <= '1';
                            currentState <= WaitForStopLow;
                        else
                            tx <= '1';
                            busy <= '0';
                        end if;
                    when WaitForStopLow =>
                        busy <= '1';
                        tx <= '1';
                        if (baudPulse = '0') then
                            currentState <= WaitForStopPulse;
                        end if;
                    when WaitForStopPulse =>
                        busy <= '1';
                        if (baudPulse = '1') then
                            tx <= '0';
                            currentState <= WaitForDataLow;
                        else
                            tx <= '1';
                        end if;
                    when WaitForDataLow =>
                        busy <= '1';
                        tx <= '0';
                        if (baudPulse = '0') then
                            currentState <= WaitForDataHigh;
                        end if;
                    when WaitForDataHigh =>
                        busy <= '1';
                        if (baudPulse = '1') then
                            tx <= data(7);
                            currentState <= SentDataBit;
                        else
                            tx <= '0';
                        end if;
                    when SentDataBit =>
                        tx <= data(bitCount);
                        busy <= '1';
                        if (baudPulse = '0') then
                            currentState <= WaitForBitPulse;
                        end if;
                    when WaitForBitPulse =>
                        if (baudPulse = '1' and bitCount = 0) then
                            currentState <= WaitForReady;
                            tx <= '1';
                            bitCount <= 7;
                            busy <= '0';
                        elsif (baudPulse = '1') then
                            currentState <= SentDataBit;
                            tx <= data(bitCount - 1);
                            bitCount <= bitCount - 1;
                            busy <= '1';
                        else
                            tx <= data(bitCount);
                            busy <= '1';
                        end if;
                    when others =>
                        null;
                end case;
            end if;
        end process;
    end Behavioral;

    """

    /// Check that the UARTTransmitter has the correct `VHDL` code.
    func testUARTTransmitter() {
        XCTAssertEqual(VHDLFile.uartTransmitter.rawValue, expected)
    }

}
