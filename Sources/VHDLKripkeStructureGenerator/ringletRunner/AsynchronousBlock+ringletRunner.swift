// AsynchronousBlock+ringletRunner.swift
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

    init?<T>(ringletRunnerFor representation: T) where T: MachineVHDLRepresentable {
        guard
            let componentLabel = VariableName(rawValue: "\(representation.machine.name.rawValue)_inst"),
            let component = ComponentInstantiation(
                machineRunnerInvocationFor: representation, record: .machine, label: componentLabel
            ),
            let process = ProcessBlock(ringletRunnerFor: representation)
        else {
            return nil
        }
        self = .blocks(blocks: [.component(block: component), .process(block: process)])
    }

}

extension ProcessBlock {

    init?<T>(
        ringletRunnerFor representation: T,
        clock clk: VariableName = .clk,
        recordName record: VariableName = .machine,
        tracker: VariableName = .tracker
    ) where T: MachineVHDLRepresentable {
        guard
            let waitForStart = WhenCase(waitForStartFor: representation, record: record, tracker: tracker),
            let executing = WhenCase(executingFor: representation, record: record, tracker: tracker)
        else {
            return nil
        }
        let code = SynchronousBlock.ifStatement(block: .ifStatement(
            condition: .conditional(condition: .edge(value: .rising(
                expression: .reference(variable: .variable(reference: .variable(name: clk)))
            ))),
            ifBlock: .caseStatement(block: CaseStatement(
                condition: .reference(variable: .variable(reference: .variable(name: tracker))),
                cases: [
                    waitForStart,
                    .waitForMachineStart(record: record, tracker: tracker),
                    executing,
                    .waitForFinish(record: record, tracker: tracker),
                    .othersNull
                ]
            ))
        ))
        self.init(sensitivityList: [], code: code)
    }

}

extension WhenCase {

    init?<T>(
        waitForStartFor representation: T, record: VariableName = .machine, tracker: VariableName = .tracker
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let allOutputs: [VariableName] = machine.externalSignals.filter { $0.mode == .output }.map(\.name)
            + machine.machineSignals.map(\.name)
            + machine.stateVariables.flatMap { (state, variables) in
                let preamble = "STATE_\(state.rawValue)_"
                // swiftlint:disable:next force_unwrapping
                return variables.map { VariableName(pre: preamble, name: $0.name)! }
            }
        let machineInputs: [IndexedValue] = allOutputs.compactMap {
            guard let recordName = VariableName(pre: "\(machine.name.rawValue)_", name: $0) else {
                return nil
            }
            return IndexedValue(
                index: .index(value: .reference(variable: .variable(reference: .variable(name: recordName)))),
                value: .reference(variable: .variable(reference: .variable(name: $0)))
            )
        }
        guard allOutputs.count == machineInputs.count else {
            return nil
        }
        let inputs = machine.externalSignals.filter { $0.mode != .output }.map {
            IndexedValue(
                index: .index(value: .reference(variable: .variable(reference: .variable(name: $0.name)))),
                value: .reference(variable: .variable(reference: .variable(name: $0.name)))
            )
        }
        let externalUpdate = machine.externalSignals.filter { $0.mode == .input }.map {
            SynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .member(access: MemberAccess(
                    record: record, member: .variable(name: $0.name)
                ))),
                value: .reference(variable: .variable(reference: .variable(name: $0.name)))
            ))
        }
        let allInternals = machine.externalSignals.filter { $0.mode != .input }.map(\.name)
            + machine.machineSignals.map(\.name)
            + machine.stateVariables.flatMap { (state, variables) in
                let preamble = "STATE_\(state.rawValue)_"
                // swiftlint:disable:next force_unwrapping
                return variables.map { VariableName(pre: preamble, name: $0.name)! }
            }
        let internalsUpdate: [SynchronousBlock] = allInternals.compactMap {
            guard
                let member = VariableName(pre: "\(machine.name.rawValue)_", name: $0, post: "In"),
                let value = VariableName(pre: "\(machine.name.rawValue)_", name: $0)
            else {
                return nil
            }
            return SynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .member(access: MemberAccess(
                    record: record, member: .variable(name: member)
                ))),
                value: .reference(variable: .variable(reference: .variable(name: value)))
            ))
        }
        let code = SynchronousBlock.ifStatement(block: .ifElse(
            condition: .conditional(condition: .comparison(value: .equality(
                lhs: .reference(variable: .variable(reference: .variable(name: .reset))),
                rhs: .literal(value: .bit(value: .high))
            ))),
            ifBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: tracker)),
                    value: .reference(variable: .variable(reference: .variable(name: .waitForMachineStart)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .reset)
                    ))),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .readSnapshotState)),
                    value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                        values: inputs + [
                            IndexedValue(
                                index: .index(value: .reference(variable: .variable(
                                    reference: .variable(name: .state)
                                ))),
                                value: .reference(variable: .variable(reference: .variable(name: .state)))
                            )
                        ] + machineInputs + [
                            IndexedValue(
                                index: .index(value: .reference(
                                    variable: .variable(reference: .variable(name: .executeOnEntry))
                                )),
                                value: Expression.conditional(condition: .comparison(value: .notEquals(
                                    lhs: .reference(variable: .variable(
                                        reference: .variable(name: .previousRinglet)
                                    )),
                                    rhs: .reference(variable: .variable(reference: .variable(name: .state)))
                                )))
                            )
                        ]
                    ))))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .finished)),
                    value: .literal(value: .boolean(value: false))
                ))
            ]),
            elseBlock: .blocks(blocks: externalUpdate + [
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .currentStateIn)
                    ))),
                    value: .reference(variable: .variable(reference: .variable(name: .state)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .internalStateIn)
                    ))),
                    value: .reference(variable: .variable(reference: .variable(name: .readSnapshot)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .targetStateIn)
                    ))),
                    value: .reference(variable: .variable(reference: .variable(name: .state)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .reset)
                    ))),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .goalInternalState)
                    ))),
                    value: .reference(variable: .variable(reference: .variable(name: .writeSnapshot)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .previousRingletIn)
                    ))),
                    value: .reference(variable: .variable(reference: .variable(name: .previousRinglet)))
                ))
            ] + internalsUpdate)
        ))
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .waitForStart)
            ))),
            code: .blocks(blocks: [
                code,
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(reference: .variable(name: .state)))
                ))
            ])
        )
    }

    init?<T>(
        executingFor representation: T, record: VariableName = .machine, tracker: VariableName = .tracker
    ) where T: MachineVHDLRepresentable {
        nil
    }

    static func waitForFinish(record: VariableName = .machine, tracker: VariableName = .tracker) -> WhenCase {
        WhenCase(
            condition: .expression(expression: .reference(
                variable: .variable(reference: .variable(name: .waitForFinish))
            )),
            code: .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .reset))),
                    rhs: .literal(value: .bit(value: .low))
                ))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .member(access: MemberAccess(
                            record: record, member: .variable(name: .reset)
                        ))),
                        value: .literal(value: .bit(value: .low))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: tracker)),
                        value: .reference(variable: .variable(
                            reference: .variable(name: .waitForStart)
                        ))
                    ))
                ])
            ))
        )
    }

    static func waitForMachineStart(
        record: VariableName = .machine, tracker: VariableName = .tracker
    ) -> WhenCase {
        WhenCase(
            condition: .expression(expression: .reference(
                variable: .variable(reference: .variable(name: .waitForMachineStart))
            )),
            code: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .member(access: MemberAccess(
                        record: record, member: .variable(name: .reset)
                    ))),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: tracker)),
                    value: .reference(variable: .variable(reference: .variable(name: .executing)))
                ))
            ])
        )
    }

}
