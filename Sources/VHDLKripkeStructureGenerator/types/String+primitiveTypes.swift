// String+primitiveTypes.swift
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

extension String {

    static let primitiveTypes = """
    library IEEE;
    use IEEE.std_logic_1164.all;

    package PrimitiveTypes is
        type stdLogicTypes_t is array (0 to 2) of std_logic;
        constant stdLogicTypes: stdLogicTypes_t := (0 => '0', 1 => '1', 2 => 'Z');
        type BitTypes_t is array (0 to 1) of bit;
        constant bitTypes: BitTypes_t := (0 => '0', 1 => '1');
        type BooleanTypes_t is array (0 to 1) of boolean;
        constant booleanTypes: BooleanTypes_t := (0 => false, 1 => true);
        function boolToStdLogic(value: boolean) return std_logic;
        function encodedToStdLogic(value: std_logic_vector(1 downto 0)) return std_logic;
        function encodedToStdULogic(value: std_logic_vector(1 downto 0)) return std_ulogic;
        function stdLogicToBool(value: std_logic) return boolean;
        subtype slv2 is std_logic_vector(1 downto 0);
        function stdLogicEncoded(value: std_logic) return slv2;
        function stdULogicEncoded(value: std_ulogic) return slv2;
    end package PrimitiveTypes;

    package body PrimitiveTypes is
        function boolToStdLogic(value: boolean) return std_logic is
        begin
            if (value) then
                return '1';
            else
                return '0';
            end if;
        end function;
        function encodedToStdLogic(value: std_logic_vector(1 downto 0)) return std_logic is
        begin
            case value is
                when "01" =>
                    return '1';
                when "11" =>
                    return 'Z';
                when others =>
                    return '0';
            end case;
        end function;
        function encodedToStdULogic(value: std_logic_vector(1 downto 0)) return std_ulogic is
        begin
            case value is
                when "01" =>
                    return '1';
                when "11" =>
                    return 'Z';
                when others =>
                    return '0';
            end case;
        end function;
        function stdLogicToBool(value: std_logic) return boolean is
        begin
            return value = '1';
        end function;
        function stdLogicEncoded(value: std_logic) return slv2 is
        begin
            if (value = '1') then
                return "01";
            elsif (value = '0') then
                return "00";
            elsif (value = 'Z') then
                return "11";
            else
                return "00";
            end if;
        end function;
        function stdULogicEncoded(value: std_ulogic) return slv2 is
        begin
            if (value = '1') then
                return "01";
            elsif (value = '0') then
                return "00";
            elsif (value = 'Z') then
                return "11";
            end if;
        end function;
    end package body PrimitiveTypes;

    """

}
