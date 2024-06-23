// ArchitectureHead+cache.swift
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

extension ArchitectureHead {

    init?(cacheName name: VariableName, elementSize size: Int, numberOfElements: Int) {
        guard size > 0, numberOfElements > 0 else {
            return nil
        }
        guard size <= 30 else {
            fatalError("Large element sizes are currently not supported!")
        }
        let elementsPerAddress = 31 / (size + 1)
        let numberOfAddresses = max(1, numberOfElements * (size + 1) / 31)
        guard
            let addressBits = BitLiteral.bitsRequired(for: numberOfElements - 1),
            addressBits <= 32,
            let decoderName = VariableName(rawValue: name.rawValue + "Decoder"),
            let encoderName = VariableName(rawValue: name.rawValue + "Encoder"),
            let dividerName = VariableName(rawValue: name.rawValue + "Divider"),
            let bramName = VariableName(rawValue: name.rawValue + "BRAM"),
            let encoder = Entity(
                encoderName: encoderName, numberOfElements: elementsPerAddress, elementSize: size
            ),
            let decoder = Entity(
                decoderName: decoderName, numberOfElements: elementsPerAddress, elementSize: size
            ),
            let divider = Entity(dividerName: dividerName, size: addressBits),
            let bram = Entity(bramName: bramName, numberOfAddresses: numberOfAddresses),
            let cacheTypeName = VariableName(rawValue: name.rawValue + "Cache_t"),
            let enablesTypeName = VariableName(rawValue: name.rawValue + "Enables_t"),
            let internalType = VariableName(rawValue: name.rawValue + "InternalState_t")
        else {
            return nil
        }
        let elementType = SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: size - 1)),
            lower: .literal(value: .integer(value: 0))
        )))
        let arraySize = VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: elementsPerAddress - 1))
        )
        let cacheType = HeadStatement.definition(value: .type(value: .array(value: ArrayDefinition(
            name: cacheTypeName,
            size: [arraySize],
            elementType: .signal(type: elementType)
        ))))
        let cache = HeadStatement.definition(value: .signal(
            value: LocalSignal(type: .alias(name: cacheTypeName), name: .cache)
        ))
        let cacheIndex = HeadStatement.definition(value: .signal(value: LocalSignal(
            type: .signal(type: .ranged(type: .integer(size: arraySize))),
            name: .cacheIndex
        )))
        let cacheSignals = [cacheType, cache, cacheIndex]
        let expanderTypes = [
            HeadStatement.definition(value: .type(value: .array(value: ArrayDefinition(
                name: enablesTypeName,
                size: [arraySize],
                elementType: .signal(type: .stdLogic)
            )))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: enablesTypeName), name: .enables
            )))
        ]
        let decoderTypes = [
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: .alias(name: enablesTypeName), name: .readEnables
            ))),
            .definition(value: .signal(
                value: LocalSignal(type: .alias(name: cacheTypeName), name: .readCache)
            ))
        ]
        let ramSignals = [
            HeadStatement.definition(value: .signal(value: LocalSignal(type: .logicVector32, name: .di))),
            .definition(value: .signal(value: LocalSignal(type: .logicVector32, name: .index))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .weBRAM))),
            .definition(value: .signal(value: LocalSignal(type: .logicVector32, name: .currentValue))),
            .definition(value: .signal(value: LocalSignal(type: .logicVector32, name: .memoryAddress)))
        ]
        let unsignedAddressType = SignalType.ranged(type: .unsigned(size: .downto(
            upper: .literal(value: .integer(value: addressBits - 1)),
            lower: .literal(value: .integer(value: 0))
        )))
        guard
            let denominatorConstant = ConstantSignal(
                name: .denominator,
                type: unsignedAddressType,
                value: .literal(value: .vector(value: .bits(value: BitVector(
                    values: BitLiteral.bitVersion(of: elementsPerAddress, bitsRequired: addressBits)
                ))))
            ),
            let internalStateType = EnumerationDefinition(
                name: internalType,
                nonEmptyValues: [
                    .initial, .waitForNewDataType, .writeElement, .incrementIndex, .resetEnables, .error
                ]
            )
        else {
            return nil
        }
        let dividerTypes = [
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: unsignedAddressType, name: .unsignedAddress
            ))),
            .definition(value: .constant(value: denominatorConstant)),
            .definition(value: .signal(value: LocalSignal(
                type: unsignedAddressType, name: .remainder
            )))
        ]
        let logicSignals = [
            HeadStatement.definition(value: .type(value: .enumeration(value: internalStateType))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: internalType), name: .internalState
            )))
        ]
        let components = [encoder, decoder, divider, bram].map {
            HeadStatement.definition(value: .component(value: ComponentDefinition(entity: $0)))
        }
        self.init(
            statements: cacheSignals + ramSignals + expanderTypes + decoderTypes + dividerTypes
                + logicSignals + components
        )
    }

}
