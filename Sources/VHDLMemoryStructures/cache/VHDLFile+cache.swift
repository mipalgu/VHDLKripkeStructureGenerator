// VHDLFile+cache.swift
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

import Utilities
import VHDLParsing

/// Add cache creation.
extension VHDLFile {

    /// Create a cache of elements that may be mapped to underlying BRAM structures.
    /// 
    /// This initialiser creates a cache of elements that may be smaller than 32-bits and therefore needs to
    /// be encoded into an appropriate 32-bit aligned memory structure. The interface of the cache hides the
    /// underlying mapping into BRAM and instead provides addresses based on the specific element rather
    /// than the underlying memory address. For example, 3 elements each 4 bits are addresses as element 0, 1,
    /// and 2 respectively rather than sharing address 0 within a 32-bit aligned memory space.
    /// 
    /// The entity of this cache is defined based on element size and reachable address space based on the
    /// number of elements. An entity with 12 3-bit elements may look like the example below:
    /// ```VHDL
    /// entity Cache is
    ///     port(
    ///         clk: in std_logic;
    ///         address: in std_logic_vector(3 downto 0);
    ///         data: in std_logic_vector(2 downto 0);
    ///         we: in std_logic;
    ///         ready: in std_logic;
    ///         busy: out std_logic;
    ///         value: out std_logic_vector(2 downto 0);
    ///         value_en: out std_logic;
    ///         lastAddress: out std_logic_vector(3 downto 0)
    ///     );
    /// end Cache;
    /// ````
    /// 
    /// Each element within the cache is encoded together with an enable bit that indicates whether the
    /// element is present or not. This allows the cache to be partially filled and the enable bit to be used
    /// to determine which elements are within the dangling memory space. Read and write operations are
    /// supported through a `we` (write enable) bit that is `high` when writing and `low` when reading. The
    /// `value` output describes the current element at the given address and is paired with `value_en` to
    /// indicate whether an element exists at the given address. The `data` signal specifies the
    /// new data to be written to the cache when `we` is `high`.
    /// 
    /// To perform a write, the data is set with the new element and the `we` and `ready` signals are set
    /// `high`. The write will only be initiated when the `busy` signal is `low`. When a write happens, the
    /// `busy` signal will go `high` until the write is complete. The `lastAddress` signal will contain the
    /// address of the last write operation.
    /// 
    /// To perform a read, the address signal is set to the read address, the `we` signal is set `low` and the
    /// `ready` signal is set `high`. The read will only be performed when the `busy` signal is `high`. The
    /// read will take exactly 1 clock cycle to finish and will not change the `busy` signal during the
    /// operation. The `value` signal will contain the element at the given address and the `value_en` signal
    /// will be `high` if the element is present and `low` if the element is not present.
    /// - Parameters:
    ///   - name: The name of the cache.
    ///   - size: The size of the elements stored within the cache.
    ///   - numberOfElements: The number of elements to store in the cache.
    /// - Warning: Please ensure `elementSize` is less than or equal to 30 bits as large elements are
    /// currently not supported and will cause the program to crash.
    @inlinable
    public init?(cacheName name: VariableName, elementSize size: Int, numberOfElements: Int) {
        guard
            let entity = Entity(cacheName: name, elementSize: size, numberOfElements: numberOfElements),
            let architecture = Architecture(
                cacheName: name, elementSize: size, numberOfElements: numberOfElements
            )
        else {
            return nil
        }
        self.init(
            architectures: [architecture],
            entities: [entity],
            includes: [
                .library(value: .ieee), .include(statement: .stdLogic1164), .include(statement: .numericStd)
            ]
        )
    }

}
