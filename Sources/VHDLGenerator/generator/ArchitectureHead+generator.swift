// ArchitectureHead+generator.swift
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

import Utilities
import VHDLMachines
import VHDLMemoryStructures
import VHDLParsing

extension ArchitectureHead {

    init?<T>(generatorFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let constants = [
            VariableName.initial,
            .setJob,
            .checkForDuplicate,
            .verifyDuplicate,
            .checkIfFinished,
            .verifyFinished,
            .hasFinished,
            .chooseNextInsertion,
            .hasError
        ].enumerated().map {
            HeadStatement.definition(value: .constant(value: ConstantSignal(
                name: $1,
                type: .logicVector8,
                value: .literal(value: .vector(value: .bits(value: BitVector(
                    values: BitLiteral.bitVersion(of: $0, bitsRequired: 8)
                ))))
            )!))
        }
        var startIndex = constants.count
        let stateInternals = representation.machine.states.enumerated().flatMap {
            let internals = [
                HeadStatement.definition(value: .constant(value: ConstantSignal(
                    name: VariableName(rawValue: "Update\($1.name.rawValue)PendingStates")!,
                    type: .logicVector8,
                    value: .literal(value: .vector(value: .bits(value: BitVector(
                        values: BitLiteral.bitVersion(of: startIndex, bitsRequired: 8)
                    ))))
                )!)),
                HeadStatement.definition(value: .constant(value: ConstantSignal(
                    name: VariableName(rawValue: "Start\($1.name.rawValue)")!,
                    type: .logicVector8,
                    value: .literal(value: .vector(value: .bits(value: BitVector(
                        values: BitLiteral.bitVersion(of: startIndex + 1, bitsRequired: 8)
                    ))))
                )!)),
                HeadStatement.definition(value: .constant(value: ConstantSignal(
                    name: VariableName(rawValue: "Reset\($1.name.rawValue)Ready")!,
                    type: .logicVector8,
                    value: .literal(value: .vector(value: .bits(value: BitVector(
                        values: BitLiteral.bitVersion(of: startIndex + 2, bitsRequired: 8)
                    ))))
                )!)),
                HeadStatement.definition(value: .constant(value: ConstantSignal(
                    name: VariableName(rawValue: "Check\($1.name.rawValue)Finished")!,
                    type: .logicVector8,
                    value: .literal(value: .vector(value: .bits(value: BitVector(
                        values: BitLiteral.bitVersion(of: startIndex + 3, bitsRequired: 8)
                    ))))
                )!))
            ]
            startIndex += internals.count
            return internals
        }
        let numberOfPendingStates = machine.numberOfPendingStates
        let numberOfTargetStates = machine.numberOfTargetStates
        let pendingIndexSize = VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: numberOfPendingStates))
        )
        let targetIndexSize = VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: numberOfTargetStates))
        )
        let stateSignals = machine.states.flatMap {
            let name = $0.name.rawValue
            let writeSnapshot = Record(writeSnapshotFor: $0, in: representation)!
            let types = writeSnapshot.types.filter { $0.name != .nextState }
            let typeSignals = types.map {
                LocalSignal(type: $0.type, name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!)
            }
            return typeSignals + [
                LocalSignal(type: .stdLogic, name: VariableName(rawValue: "\(name)Ready")!),
                LocalSignal(type: .stdLogic, name: VariableName(rawValue: "\(name)Busy")!),
                LocalSignal(
                    type: .alias(name: .targetStatesType),
                    name: VariableName(rawValue: "\(name)TargetStates")!
                ),
                LocalSignal(type: .boolean, name: VariableName(rawValue: "\(name)Working")!),
                LocalSignal(
                    type: .ranged(type: .integer(size: targetIndexSize)),
                    name: VariableName(rawValue: "\(name)Index")!
                ),
                LocalSignal(
                    type: machine.targetStateEncoding,
                    name: VariableName(rawValue: "current\(name)TargetState")!
                )
            ]
        }
        .map {
            HeadStatement.definition(value: .signal(value: $0))
        }
        let genSignals = machine.states.map {
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: .stdLogic, name: VariableName(rawValue: "gen\($0.name.rawValue)Ready")!
            )))
        }
        let generators = machine.states.map {
            let entity = Entity(stateGeneratorFor: $0, in: representation)!
            return HeadStatement.definition(value: .component(value: ComponentDefinition(entity: entity)))
        }
        let indexVariables: [HeadStatement] = [
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: .pendingStatesType),
                name: .pendingStates,
                defaultValue: .literal(value: .vector(value: .indexed(values: IndexedVector(values: [
                    IndexedValue(index: .others, value: .literal(value: .vector(value: .indexed(
                        values: IndexedVector(values: [
                            IndexedValue(index: .others, value: .bit(value: .low))
                        ])
                    ))))
                ]))))
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: .targetStatesType),
                name: .observedStates,
                defaultValue: .literal(value: .vector(value: .indexed(values: IndexedVector(values: [
                    IndexedValue(index: .others, value: .literal(value: .vector(value: .indexed(
                        values: IndexedVector(values: [
                            IndexedValue(index: .others, value: .bit(value: .low))
                        ])
                    ))))
                ]))))
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: pendingIndexSize)),
                name: .pendingStateIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: targetIndexSize)),
                name: .observedIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: .to(
                    lower: .literal(value: .integer(value: 0)),
                    upper: .literal(value: .integer(value: max(0, numberOfPendingStates - 1)))
                ))),
                name: .pendingSearchIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: .to(
                    lower: .literal(value: .integer(value: 0)),
                    upper: .literal(value: .integer(value: max(0, numberOfTargetStates - 1)))
                ))),
                name: .observedSearchIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: pendingIndexSize)),
                name: .pendingInsertIndex
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .integer(size: pendingIndexSize)),
                name: .maxInsertIndex
            )))
        ]
        let stateTrackers: [HeadStatement] = [
            .definition(value: .signal(value: LocalSignal(type: .logicVector8, name: .fromState))),
            .definition(value: .signal(value: LocalSignal(type: .logicVector8, name: .nextState))),
            .definition(value: .signal(value: LocalSignal(
                type: .logicVector8,
                name: .currentState,
                defaultValue: .literal(value: .vector(value: .bits(value: BitVector(
                    values: [BitLiteral](repeating: .low, count: 8)
                ))))
            )))
        ]
        let targetValues: [HeadStatement] = [
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .isDuplicate))),
            .definition(value: .signal(value: LocalSignal(type: .boolean, name: .isFinished))),
            .definition(value: .signal(value: LocalSignal(
                type: machine.targetStateEncoding,
                name: .currentObservedState
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: machine.targetStateEncoding,
                name: .currentPendingState
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: machine.targetStateEncoding,
                name: .currentWorkingPendingState
            )))
        ]
        self.init(
            statements: stateTrackers + constants + stateInternals + indexVariables + stateSignals
                + targetValues + genSignals + generators
        )
    }

    init?<T>(sequentialGeneratorFor representation: T) where T: MachineVHDLRepresentable {
        let machine: Machine = representation.machine
        let constants: [VariableName] = [
            .initial, .setRead, .resetRead, .incrementIndex, .setJob, .checkIfFinished, .hasFinished,
            .waitForRead
        ]
        let stateInternals = machine.states.flatMap {
            [
                VariableName(rawValue: "Start\($0.name.rawValue)")!,
                VariableName(rawValue: "Reset\($0.name.rawValue)")!,
            ]
        }
        guard
            let internalStateName = VariableName(
                rawValue: "\(representation.entity.name.rawValue)GeneratorInternalState_t"
            ),
            let internalStateEnum = EnumerationDefinition(
                name: internalStateName, nonEmptyValues: constants + stateInternals
            ),
            let addressBits = BitLiteral.bitsRequired(for: max(1, machine.numberOfTargetStates - 1)),
            let cache = VHDLFile(targetStatesCacheFor: representation)?.entities.first,
            let monitorName = VariableName(
                rawValue: representation.entity.name.rawValue + "TargetStatesCacheMonitor"
            ),
            let monitor = VHDLFile(
                cacheMonitorName: monitorName, numberOfMembers: machine.states.count + 1, cache: cache
            )?.entities.first
        else {
            return nil
        }
        let addressType = SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: max(0, addressBits - 1))),
            lower: .literal(value: .integer(value: 0))
        )))
        let dataType = SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: max(0, machine.targetStateBits - 2))),
            lower: .literal(value: .integer(value: 0))
        )))
        let validSignals: Set<VariableName> = [.address, .data, .we, .ready]
        let monitorSignals = cache.port.signals.filter { validSignals.contains($0.name) }
        let stateSignals = machine.states.enumerated()
            .flatMap { index, state in
                let name = state.name.rawValue
                let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
                let types = writeSnapshot.types.filter { $0.name != VariableName.nextState }
                let typeSignals = types.map {
                    LocalSignal(type: $0.type, name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!)
                }
                let stateMonitorSignals = monitorSignals.map {
                    LocalSignal(
                        type: $0.type,
                        name: VariableName(rawValue: "targetStates\($0.name.rawValue)\(index + 1)")!
                    )
                }
                return typeSignals + stateMonitorSignals + [
                    LocalSignal(type: .stdLogic, name: VariableName(rawValue: "targetStatesen\(index + 1)")!),
                    LocalSignal(type: .stdLogic, name: VariableName(rawValue: "\(name)Ready")!),
                    LocalSignal(type: .stdLogic, name: VariableName(rawValue: "\(name)Busy")!)
                ]
            }
            .map {
                HeadStatement.definition(value: .signal(value: $0))
            }
        let generatorSignals = monitorSignals.map {
            LocalSignal(type: $0.type, name: VariableName(rawValue: "targetStates\($0.name.rawValue)0")!)
        }
        let generatorCacheSignals = generatorSignals + [
            LocalSignal(type: .stdLogic, name: VariableName(rawValue: "targetStatesen0")!),
            LocalSignal(type: dataType, name: VariableName(rawValue: "targetStatesvalue")!),
            LocalSignal(type: .stdLogic, name: VariableName(rawValue: "targetStatesvalue_en")!),
            LocalSignal(type: .stdLogic, name: VariableName(rawValue: "targetStatesbusy")!),
            LocalSignal(type: addressType, name: VariableName(rawValue: "targetStateslastAddress")!)

        ]
        let generatorMonitorSignals = generatorCacheSignals.map {
            HeadStatement.definition(value: .signal(value: $0))
        }
        let genSignals = machine.states.map {
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: .stdLogic, name: VariableName(rawValue: "gen\($0.name.rawValue)Ready")!
            )))
        }
        let generators = machine.states.map {
            let entity = Entity(sequentialStateGeneratorFor: $0, in: representation)!
            return HeadStatement.definition(value: .component(value: ComponentDefinition(entity: entity)))
        }
        let monitorDefinition = HeadStatement.definition(
            value: .component(value: ComponentDefinition(entity: monitor))
        )
        let variables: [HeadStatement] = [
            .definition(value: .type(value: .enumeration(value: internalStateEnum))),
            .definition(value: .signal(value: LocalSignal(
                type: .alias(name: internalStateName),
                name: .currentState,
                defaultValue: .reference(variable: .variable(reference: .variable(name: .initial)))
            ))),
            .definition(value: .signal(value: LocalSignal(
                type: .ranged(type: .unsigned(size: .downto(
                    upper: .literal(value: .integer(value: addressBits - 1)),
                    lower: .literal(value: .integer(value: 0))
                ))),
                name: .pendingStateIndex
            ))),
            .definition(value: .signal(value: LocalSignal(type: dataType, name: .currentTargetState)))
        ]
        self.init(
            statements: variables + stateSignals + generatorMonitorSignals + genSignals + generators
                + [monitorDefinition]
        )
    }

}
