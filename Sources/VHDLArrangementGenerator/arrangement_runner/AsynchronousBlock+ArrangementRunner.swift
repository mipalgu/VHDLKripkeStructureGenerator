// AsynchronousBlock+ArrangementRunner.swift
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

import VHDLGenerator
import VHDLMachines
import VHDLParsing

extension AsynchronousBlock {

    init?<T>(
        arrangementRunnerFor arrangement: T,
        machines: [VariableName: any MachineVHDLRepresentable]
    ) where T: ArrangementVHDLRepresentable {
        guard
            let asyncCode = AsynchronousBlock(
                asynchronousCodeInArrangementRunner: arrangement, machines: machines
            ),
            let processBlock = ProcessBlock(arrangementRunnerFor: arrangement, machines: machines)
        else {
            return nil
        }
        self = .blocks(blocks: [asyncCode, .process(block: processBlock)])
    }

    init?<T>(
        asynchronousCodeInArrangementRunner representation: T,
        machines: [VariableName: any MachineVHDLRepresentable]
    ) where T: ArrangementVHDLRepresentable {
        let runnerFiles: [(VariableName, VHDLFile)] = machines.sorted { $0.key < $1.key }.compactMap {
            guard
                let representation = $0.value as? MachineRepresentation,
                let file = VHDLFile(ringletRunnerFor: representation)
            else {
                return nil
            }
            return ($0.key, file)
        }
        guard runnerFiles.count == machines.count else {
            return nil
        }
        let runners = [VariableName: VHDLFile](uniqueKeysWithValues: runnerFiles)
        let arrangement = representation.arrangement
        let components: [AsynchronousBlock] = arrangement.machines.compactMap {
            let name = $0.key.name
            let type = $0.key.type
            let arrangementMappings = $0.value
            guard let entity = runners[type]?.entities.first else {
                return nil
            }
            let mappings: [VariableName: VariableName] = Dictionary(
                uniqueKeysWithValues: arrangementMappings.mappings.map { ($0.destination, $0.source) }
            )
            let port = entity.port
            let componentMappings = port.signals.map {
                let signalName = $0.name
                if let arrangementSignal = mappings[signalName] {
                    return VariableMap(
                        lhs: .variable(reference: .variable(name: signalName)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(
                                rawValue: "\(representation.name.rawValue)_READ_\(arrangementSignal.rawValue)"
                            )!)
                        )))
                    )
                }
                switch signalName {
                case .clk:
                    return VariableMap(
                        lhs: .variable(reference: .variable(name: signalName)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: .clk)
                        )))
                    )
                case .reset:
                    return VariableMap(
                        lhs: .variable(reference: .variable(name: signalName)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: .reset)
                        )))
                    )
                case .state:
                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "\(name.rawValue)_READ_state")!)
                        )))
                    )
                case .previousRinglet:
                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(
                                name: VariableName(rawValue: "\(name.rawValue)PreviousRinglet")!
                            )
                        )))
                    )
                case .readSnapshotState:
                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .open
                    )
                case .writeSnapshotState:
                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(
                                name: VariableName(rawValue: "\(name.rawValue)WriteSnapshot")!
                            )
                        )))
                    )
                case .finished:
                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(
                                name: VariableName(rawValue: "finished")!
                            )
                        )))
                    )
                case .nextState:
                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(
                                name: VariableName(rawValue: "\(name.rawValue)NextState")!
                            )
                        )))
                    )
                default:

                    return VariableMap(
                        lhs: .variable(reference: .variable(
                            name: signalName
                        )),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(
                                name: VariableName(rawValue: "\(name.rawValue)_READ_\(signalName.rawValue)")!
                            )
                        )))
                    )
                }
            }
            return AsynchronousBlock.component(block: ComponentInstantiation(
                label: name,
                name: entity.name,
                port: PortMap(variables: componentMappings)
            ))
        }
        self = .blocks(blocks: components)
    }

}
