// ArchitectureHead+ArrangementRunner.swift
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
import VHDLGenerator
import VHDLMachines
import VHDLParsing

extension ArchitectureHead {

    public init?(
        arrangementRunnerFor arrangement: Arrangement,
        name: VariableName,
        machines: [VariableName: any MachineVHDLRepresentable]
    ) {
        let runners: [VHDLFile] = machines.sorted { $0.key < $1.key }.compactMap {
            guard let representation = $0.value as? MachineRepresentation else {
                return nil
            }
            return VHDLFile(ringletRunnerFor: representation)
        }
        guard
            runners.count == machines.count,
            let internalType = VariableName(rawValue: "\(name.rawValue)InternalState_t"),
            let internalTypeEnum = EnumerationDefinition(
                name: internalType,
                nonEmptyValues: [
                    .initial, .waitToStart, .waitForMachineStart, .waitForFinish, .setRingletValue
                ]
            )
        else {
            return nil
        }
        let runnerComponents = runners.map {
            HeadStatement.definition(value: .component(value: ComponentDefinition(entity: $0.entities[0])))
        }
        let internalStateType = HeadStatement.definition(value: .type(value: .enumeration(
            value: internalTypeEnum
        )))
        let internalState = HeadStatement.definition(value: .signal(value: LocalSignal(
            type: .alias(name: internalType),
            name: .internalState,
            defaultValue: .reference(variable: .variable(reference: .variable(name: .initial)))
        )))
        let internalDefinition = [internalStateType, internalState]
        let machineSignals = arrangement.machines.flatMap {
            let name = $0.key.name
            let type = $0.key.type
            guard let representation = machines[type] else {
                fatalError("No representation for \(name)!")
            }
            let currentState: [Type] = representation.architectureHead.statements.compactMap {
                switch $0 {
                case .definition(value: .signal(let signal)):
                    guard signal.name == .currentState else {
                        return nil
                    }
                    return signal.type
                default:
                    return nil
                }
            }
            guard currentState.count == 1 else {
                fatalError("Invalid representation for \(name)!")
            }
            let stateType = currentState[0]
            let types = [
                HeadStatement.definition(value: .signal(value: LocalSignal(
                    type: .member(components: [
                        .work, VariableName(rawValue: "\(type.rawValue)Types")!, .readSnapshotType
                    ]),
                    name: VariableName(rawValue: "\(name.rawValue)ReadSnapshot")!
                ))),
                HeadStatement.definition(value: .signal(value: LocalSignal(
                    type: .member(components: [
                        .work, VariableName(rawValue: "\(type.rawValue)Types")!, .writeSnapshotType
                    ]),
                    name: VariableName(rawValue: "\(name.rawValue)WriteSnapshot")!
                ))),
                .definition(value: .signal(value: LocalSignal(
                    type: stateType,
                    name: VariableName(rawValue: "\(name.rawValue)PreviousRinglet")!
                )))
            ]
            let machineSignals = representation.machine.machineSignals.map {
                HeadStatement.definition(value: .signal(value: LocalSignal(
                    type: $0.type,
                    name: VariableName(rawValue: "\(name.rawValue)\($0.name.rawValue)")!
                )))
            }
            let stateSignals = representation.machine.states.flatMap { state in
                state.signals.map {
                    HeadStatement.definition(value: .signal(value: LocalSignal(
                        type: $0.type,
                        name: VariableName(
                            rawValue: "\(name.rawValue)_STATE_\(state.name.rawValue)_\($0.name.rawValue)"
                        )!
                    )))
                }
            }
            return types + machineSignals + stateSignals
        }
        let controlSignals = [
            HeadStatement.definition(value: .signal(value: LocalSignal(type: .stdLogic, name: .reset))),
            HeadStatement.definition(value: .signal(value: LocalSignal(type: .boolean, name: .finished)))
        ]
        self.init(statements: internalDefinition + machineSignals + controlSignals + runnerComponents)
    }

}
