// ArchitectureHead+ringletCache.swift
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

import VHDLMachines
import VHDLParsing

extension ArchitectureHead {

    init?<T>(
        ringletCacheFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        let ringletsPerAddress = state.ringletsPerAddress(in: representation)
        guard ringletsPerAddress >= 2 else {
            self.init(
                ringletCacheForLarge: state,
                in: representation,
                ringletsPerAddress: ringletsPerAddress,
                maxExecutionSize: maxExecutionSize
            )
            return
        }
        self.init(
            ringletCacheForSmall: state,
            in: representation,
            ringletsPerAddress: ringletsPerAddress,
            maxExecutionSize: maxExecutionSize
        )
    }

    init?<T>(
        ringletCacheForSmall state: State,
        in representation: T,
        ringletsPerAddress: Int,
        maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let machine = representation.machine
        let inputVariables = machine.externalSignals.filter { $0.mode != .output }.map(\.name)
        let invalidVariables = state.externalVariables.filter { !inputVariables.contains($0) }
        let recordTypes = readSnapshot.types.filter { !invalidVariables.contains($0.name) }
        let lastVariables = recordTypes.map {
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: Type(encodedType: $0.type)!,
                name: VariableName(pre: "last_", name: $0.name)!
            )))
        }
        let memoryIndexType = VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: state.numberOfMemoryAddresses(
                for: state, in: representation
            )))
        )
        let indexSize = state.memoryStorage(for: state, in: representation)
        let executionSize = state.executionSize(in: representation, maxExecutionSize: maxExecutionSize)
        let arrayMaxIndex = ringletsPerAddress - 1
        let arrayType = VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: arrayMaxIndex))
        )
        let statements = lastVariables + [
            LocalSignal(
                type: .alias(name: VariableName(pre: "\(state.name.rawValue)_", name: .stateExecutionType)!),
                name: .workingRinglets
            ),
            LocalSignal(type: .ranged(type: .integer(size: memoryIndexType)), name: .memoryIndex),
            LocalSignal(type: .ranged(type: .integer(size: executionSize)), name: .ringletIndex),
            LocalSignal(type: .logicVector32, name: .di),
            LocalSignal(type: .logicVector32, name: .index),
            LocalSignal(type: .boolean, name: .isDuplicate),
            LocalSignal(type: .stdLogic, name: .we)
        ].map { HeadStatement.definition(value: .signal(value: $0)) }
        let newTypes: [HeadStatement] = [
            .definition(value: .constant(value: ConstantSignal(
                name: .lastAccessibleAddress,
                type: .unsigned32bit,
                value: .functionCall(call: .custom(function: CustomFunctionCall(
                    name: .toUnsigned,
                    parameters: [
                        Argument(argument: indexSize.max),
                        Argument(argument: .literal(value: .integer(value: 32)))
                    ]
                )))
            )!)),
            .definition(value: .type(value: .array(value: ArrayDefinition(
                name: .currentRingletType,
                size: [arrayType],
                elementType: .signal(type: state.encodedType(in: representation))
            ))))
        ]
        let trackers = [
            LocalSignal(type: .logicVector32, name: .currentRingletAddress),
            LocalSignal(type: .alias(name: .currentRingletType), name: .currentRinglet),
            LocalSignal(type: .ranged(type: .integer(size: arrayType)), name: .currentRingletIndex),
            LocalSignal(type: .logicVector32, name: .cacheValue),
            LocalSignal(type: .logicVector32, name: .genValue),
            LocalSignal(type: .logicVector32, name: .genIndex),
            LocalSignal(type: .logicVector32, name: .previousReadAddress),
            LocalSignal(type: .boolean, name: .isInitial),
            LocalSignal(type: .logicVector4, name: .internalState)
        ].map { HeadStatement.definition(value: .signal(value: $0)) }
        let internalStates = [ConstantSignal].ringletCacheInternalStates.map {
            HeadStatement.definition(value: .constant(value: $0))
        }
        let entity = Entity(bramFor: state, in: representation)
        let component = [
            HeadStatement.definition(
                value: .component(value: ComponentDefinition(name: entity.name, port: entity.port))
            )
        ]
        self.init(statements: statements + newTypes + trackers + internalStates + component)
    }

    init?<T>(
        ringletCacheForLarge state: State,
        in representation: T,
        ringletsPerAddress: Int,
        maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        fatalError("Ringlet cache not fully supported for large state \(state.name).")
    }

}

/// A variable names for ringlet cache.
extension VariableName {

    /// The `cacheValue` signal.
    @usableFromInline static let cacheValue = VariableName(rawValue: "cacheValue")!

    /// The `CheckPreviousRinglets` constant.
    @usableFromInline static let checkPreviousRinglets = VariableName(rawValue: "CheckPreviousRinglets")!

    /// The `currentRinglet` signal.
    @usableFromInline static let currentRinglet = VariableName(rawValue: "currentRinglet")!

    /// The `currentRingletAddress` signal.
    @usableFromInline static let currentRingletAddress = VariableName(rawValue: "currentRingletAddress")!

    /// The `currentRingletIndex` signal.
    @usableFromInline static let currentRingletIndex = VariableName(rawValue: "currentRingletIndex")!

    /// The `CurrentRinglet_t` type.
    @usableFromInline static let currentRingletType = VariableName(rawValue: "CurrentRinglet_t")!

    /// The `Error` constant.
    @usableFromInline static let error = VariableName(rawValue: "Error")!

    /// The `genIndex` signal.
    @usableFromInline static let genIndex = VariableName(rawValue: "genIndex")!

    /// The `genValue` signal.
    @usableFromInline static let genValue = VariableName(rawValue: "genValue")!

    /// The `index` signal.
    @usableFromInline static let index = VariableName(rawValue: "index")!

    /// The `Initial` state.
    @usableFromInline static let initial = VariableName(rawValue: "Initial")!

    /// The `isDuplicate` signal.
    @usableFromInline static let isDuplicate = VariableName(rawValue: "isDuplicate")!

    /// The `isInitial` signal.
    @usableFromInline static let isInitial = VariableName(rawValue: "isInitial")!

    /// The `lastAccessibleAddress` constant.
    @usableFromInline static let lastAccessibleAddress = VariableName(rawValue: "lastAccessibleAddress")!

    /// The `memoryIndex` signal.
    @usableFromInline static let memoryIndex = VariableName(rawValue: "memoryIndex")!

    /// The `previousReadAddress` signal.
    @usableFromInline static let previousReadAddress = VariableName(rawValue: "previousReadAddress")!

    /// The `ringletIndex` signal.
    @usableFromInline static let ringletIndex = VariableName(rawValue: "ringletIndex")!

    /// The `SetRingletRAMValue` constant.
    @usableFromInline static let setRingletRAMValue = VariableName(rawValue: "SetRingletRAMValue")!

    /// The `SetRingletValue` constant.
    @usableFromInline static let setRingletValue = VariableName(rawValue: "SetRingletValue")!

    /// The `WaitForNewRinglets` constant.
    @usableFromInline static let waitForNewRinglets = VariableName(rawValue: "WaitForNewRinglets")!

    /// The `WriteElement` constant.
    @usableFromInline static let writeElement = VariableName(rawValue: "WriteElement")!

    /// The `workingRinglets` signal.
    @usableFromInline static let workingRinglets = VariableName(rawValue: "workingRinglets")!

}

/// Add common types.
extension SignalType {

    /// A 4-bit `std_logic_vector` type.
    @usableFromInline static let logicVector4 = SignalType.ranged(type: .stdLogicVector(size: .downto(
        upper: .literal(value: .integer(value: 3)), lower: .literal(value: .integer(value: 0))
    )))

    /// A 32-bit unsigned type.
    @usableFromInline static let unsigned32bit = SignalType.ranged(type: .unsigned(size: .downto(
        upper: .literal(value: .integer(value: 31)), lower: .literal(value: .integer(value: 0))
    )))

}

extension Array where Element == ConstantSignal {

    @usableFromInline static let ringletCacheInternalStates = [
        ConstantSignal(
            name: .initial,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.zero]))))
        )!,
        ConstantSignal(
            name: .waitForNewRinglets,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.one]))))
        )!,
        ConstantSignal(
            name: .writeElement,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.two]))))
        )!,
        ConstantSignal(
            name: .error,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.three]))))
        )!,
        ConstantSignal(
            name: .checkPreviousRinglets,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.four]))))
        )!,
        ConstantSignal(
            name: .setRingletValue,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.five]))))
        )!,
        ConstantSignal(
            name: .setRingletRAMValue,
            type: .logicVector4,
            value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.six]))))
        )!,
    ]

}
