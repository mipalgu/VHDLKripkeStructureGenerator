// AsynchronousBlock+generator.swift
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

extension AsynchronousBlock {

    init?<T>(generatorFor representation: T) where T: MachineVHDLRepresentable {
        guard let block = ProcessBlock(generatorFor: representation) else {
            return nil
        }
        let machine = representation.machine
        let clk = machine.clocks[machine.drivingClock]
        let generatorInvocations = machine.states.map {
            let name = $0.name.rawValue
            let entity = Entity(stateGeneratorFor: $0, in: representation)!.name
            let writeSnapshot = Record(writeSnapshotFor: $0, in: representation)!
            let types = writeSnapshot.types.filter { $0.name != .nextState }
            let variableMapping = types.map {
                VariableMap(
                    lhs: .variable(reference: .variable(name: $0.name)),
                    rhs: .expression(value: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                    ))))
                )
            }
            return AsynchronousBlock.component(block: ComponentInstantiation(
                label: VariableName(rawValue: "\(name)_generator_inst")!,
                name: entity,
                port: PortMap(variables: [
                    VariableMap(
                        lhs: .variable(reference: .variable(name: clk.name)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: clk.name)
                        )))
                    )
                ] + variableMapping + [
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .address)),
                        rhs: .expression(value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name)Address")!
                        ))))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .ready)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "gen\(name)Ready")!)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .read)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "\(name)Read")!)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .busy)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "\(name)Busy")!)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .targetStates)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "\(name)TargetStates")!)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .value)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "\(name)Value")!)
                        )))
                    ),
                    VariableMap(
                        lhs: .variable(reference: .variable(name: .lastAddress)),
                        rhs: .expression(value: .reference(variable: .variable(
                            reference: .variable(name: VariableName(rawValue: "\(name)LastAddress")!)
                        )))
                    )
                ])
            ))
        }
        let targetAssignments: [AsynchronousBlock] = [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentObservedState)),
                value: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .observedStates))),
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .observedSearchIndex)
                    )))
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentPendingState)),
                value: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .pendingStates))),
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .pendingSearchIndex)
                    )))
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentWorkingPendingState)),
                value: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .pendingStates))),
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .pendingStateIndex)
                    )))
                )))
            ))
        ]
        let stateAssignments = machine.states.flatMap {
            let name = $0.name.rawValue
            return [
                AsynchronousBlock.statement(statement: .assignment(
                    name: .variable(reference: .variable(
                        name: VariableName(rawValue: "gen\(name)Ready")!
                    )),
                    value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                        value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name)ReadReady")!
                        ))),
                        condition: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .currentState))),
                            rhs: .reference(variable: .variable(reference: .variable(name: .hasFinished)))
                        ))),
                        elseBlock: .expression(value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name)Ready")!
                        ))))
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(
                        name: VariableName(rawValue: "current\(name)TargetState")!
                    )),
                    value: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name)TargetStates")!
                        ))),
                        index: .index(value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name)Index")!
                        ))))
                    )))
                ))
            ]
        }
        self = .blocks(
            blocks: targetAssignments + generatorInvocations + stateAssignments + [.process(block: block)]
        )
    }

}
