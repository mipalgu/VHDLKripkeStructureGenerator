// MemoryStructureFactory.swift
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

import VHDLMachines
import VHDLParsing

/// A factory for creating memory structures in `VHDL`.
public struct MemoryStructureFactory {

    /// Create the factory.
    @inlinable
    public init() {}

    /// Create all the files for a cache memory structure.
    /// - Parameters:
    ///   - name: The name of the cache.
    ///   - size: The size of each element in the cache.
    ///   - numberOfElements: The total number of elements in the cache.
    /// - Returns: The VHDL files required to implement the cache.
    @inlinable
    public func createCache(name: VariableName, elementSize size: Int, numberOfElements: Int) -> [VHDLFile]? {
        guard size > 0, numberOfElements > 0 else {
            return nil
        }
        let elementsPerAddress = 31 / size
        guard elementsPerAddress > 0 else {
            return self.createLargeCache(name: name, elementSize: size, numberOfElements: numberOfElements)
        }
        let numberOfAddresses: Int
        if numberOfElements.isMultiple(of: elementsPerAddress) {
            numberOfAddresses = numberOfElements / elementsPerAddress
        } else {
            numberOfAddresses = numberOfElements / elementsPerAddress + 1
        }
        guard
            let cache = VHDLFile(cacheName: name, elementSize: size, numberOfElements: numberOfElements),
            let decoderName = VariableName(rawValue: name.rawValue + "Decoder"),
            let encoderName = VariableName(rawValue: name.rawValue + "Encoder"),
            let bramName = VariableName(rawValue: name.rawValue + "BRAM"),
            let dividerName = VariableName(rawValue: name.rawValue + "Divider"),
            let decoder = VHDLFile(
                decoderName: decoderName, numberOfElements: elementsPerAddress, elementSize: size
            ),
            let encoder = VHDLFile(
                encoderName: encoderName, numberOfElements: elementsPerAddress, elementSize: size
            ),
            let addressSize = BitLiteral.bitsRequired(for: max(1, numberOfAddresses - 1)),
            let divider = VHDLFile(dividerName: dividerName, size: addressSize),
            let bram = VHDLFile(bramName: bramName, numberOfAddresses: numberOfAddresses)
        else {
            return nil
        }
        return [cache, decoder, encoder, divider, bram]
    }

    @inlinable
    func createLargeCache(name: VariableName, elementSize size: Int, numberOfElements: Int) -> [VHDLFile]? {
        print("Creating large cache \(name) containing \(numberOfElements) elements of size \(size) bits.")
        let addressesPerElement = Int((Double(size) / 31.0).rounded(.up))
        let numberOfAddresses = addressesPerElement * numberOfElements
        guard
            let cache = VHDLFile(cacheName: name, elementSize: size, numberOfElements: numberOfElements),
            let decoderName = VariableName(rawValue: name.rawValue + "Decoder"),
            let encoderName = VariableName(rawValue: name.rawValue + "Encoder"),
            let bramName = VariableName(rawValue: name.rawValue + "BRAM"),
            let decoder = VHDLFile(
                decoderName: decoderName, numberOfElements: numberOfElements, elementSize: size
            ),
            let encoder = VHDLFile(
                encoderName: encoderName, numberOfElements: numberOfElements, elementSize: size
            ),
            let bram = VHDLFile(bramName: bramName, numberOfAddresses: numberOfAddresses)
        else {
            return nil
        }
        return [cache, decoder, encoder, bram]
    }

    /// Create the target states cache for a machine.
    /// - Parameter representation: The representation of the machine to generate the cache for.
    /// - Returns: The `VHDL` files required to implement the target states cache.
    @inlinable
    public func targetStateCache<T>(for representation: T) -> [VHDLFile]? where T: MachineVHDLRepresentable {
        guard
            let monitorName = VariableName(
                rawValue: "\(representation.entity.name.rawValue)TargetStatesCacheMonitor"
            ),
            let cache = VHDLFile(targetStatesCacheFor: representation),
            let cacheEntity = cache.entities.first,
            let monitor = VHDLFile(
                cacheMonitorName: monitorName,
                numberOfMembers: representation.machine.states.count + 1,
                cache: cacheEntity
            ),
            let encoder = VHDLFile(targetStatesEncoderFor: representation),
            let decoder = VHDLFile(targetStatesDecoderFor: representation),
            let divider = VHDLFile(targetStatesDividerFor: representation),
            let bram = VHDLFile(targetStatesBRAMFor: representation)
        else {
            return nil
        }
        return [monitor, cache, encoder, decoder, divider, bram]
    }

}
