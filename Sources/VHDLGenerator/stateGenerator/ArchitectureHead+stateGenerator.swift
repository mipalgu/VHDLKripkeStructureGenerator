// ArchitectureHead+stateGenerator.swift
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
import VHDLMemoryStructures
import VHDLParsing

extension ArchitectureHead {

    init?<T>(
        stateGeneratorFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        guard
            let runner = Entity(stateRunnerFor: state, in: representation),
            let size = state.executionSize(in: representation, maxExecutionSize: maxExecutionSize).size
        else {
            return nil
        }
        let executionIndexSize = VectorSize.to(
            lower: .literal(value: .integer(value: 0)), upper: .literal(value: .integer(value: size))
        )
        let numberOfTargets = representation.machine.numberOfTargetStates
        let indexType = VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: numberOfTargets))
        )
        let cache = Entity(ringletCacheFor: state, representation: representation)
        let internalStates = [
            (VariableName.initial, HexLiteral.zero),
            (VariableName.checkForJob, HexLiteral.one),
            (VariableName.waitForRunnerToStart, HexLiteral.two),
            (VariableName.waitForRunnerToFinish, HexLiteral.three),
            (VariableName.waitForCacheToStart, HexLiteral.four),
            (VariableName.waitForCacheToEnd, HexLiteral.five),
            (VariableName.checkForDuplicates, HexLiteral.six),
            (VariableName.error, HexLiteral.seven),
            (VariableName.addToStates, HexLiteral.eight)
        ].map {
            HeadStatement.definition(value: .constant(value: ConstantSignal(
                name: $0.0,
                type: .logicVector4,
                value: .literal(value: .vector(value: .hexademical(value: HexVector(values: [$0.1]))))
            )!))
        }
        self.init(statements: [
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .startGeneration))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .startCache))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: VariableName(
                    rawValue: "\(state.name.rawValue)_\(VariableName.stateExecutionType.rawValue)"
                )!),
                name: .ringlets
            ))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .runnerBusy))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .cacheBusy))),
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .cacheRead))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: indexType)), name: .statesIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: executionIndexSize)), name: .ringletIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: .targetStatesType), name: .states
            ))),
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .hasDuplicate))),
            .definition(value: .signal(value: LocalSignal(
                type: .logicVector4,
                name: .internalState,
                defaultValue: .literal(value: .vector(value: .hexademical(value: HexVector(values: [.zero]))))
            )))
        ] + internalStates + [
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .genRead))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .genReady))),
            .definition(value: .component(value: ComponentDefinition(entity: cache))),
            .definition(value: .component(value: ComponentDefinition(entity: runner)))
        ])
    }

    init?<T>(
        sequentialStateGeneratorFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        guard
            let runner = Entity(stateRunnerFor: state, in: representation),
            let size = state.executionSize(in: representation, maxExecutionSize: maxExecutionSize).size,
            let internalStateTypeName = VariableName(
                rawValue: "\(state.name.rawValue)GeneratorInternalState_t"
            ),
            let internalStateEnumeration = EnumerationDefinition(
                name: internalStateTypeName,
                nonEmptyValues: [
                    .initial, .checkForJob, .waitForRunnerToStart, .waitForRunnerToFinish,
                    .waitForCacheToStart, .waitForCacheToEnd, .checkForDuplicates, .error, .addToStates,
                    .resetStateIndex, .setNextTargetState, .setNextRinglet, .waitForRead, .waitForReadEnable
                ]
            ),
            let addressBits = BitLiteral.bitsRequired(for: representation.machine.numberOfTargetStates)
        else {
            return nil
        }
        let addressType = SignalType.ranged(type: .unsigned(size: .downto(
            upper: .literal(value: .integer(value: addressBits - 1)),
            lower: .literal(value: .integer(value: 0))
        )))
        let executionIndexSize = VectorSize.to(
            lower: .literal(value: .integer(value: 0)), upper: .literal(value: .integer(value: size))
        )
        let cache = Entity(ringletCacheFor: state, representation: representation)
        self.init(statements: [
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .startGeneration))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .startCache))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: VariableName(
                    rawValue: "\(state.name.rawValue)_\(VariableName.stateExecutionType.rawValue)"
                )!),
                name: .ringlets
            ))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .runnerBusy))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .cacheBusy))),
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .cacheRead))),
            .definition(value: .signal(value: LocalSignal(type: addressType, name: .statesIndex))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: executionIndexSize)), name: .ringletIndex
            ))),
            .definition(value: .type(value: .enumeration(value: internalStateEnumeration))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: internalStateTypeName),
                name: .internalState,
                defaultValue: .reference(variable: .variable(reference: .variable(name: .initial)))
            ))),
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .genRead))),
            .definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .genReady))),
            .definition(value: .component(value: ComponentDefinition(entity: cache))),
            .definition(value: .component(value: ComponentDefinition(entity: runner)))
        ])
    }

}
