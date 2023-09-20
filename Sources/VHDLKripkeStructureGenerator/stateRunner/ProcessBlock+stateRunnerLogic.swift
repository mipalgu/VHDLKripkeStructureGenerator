// ProcessBlock+stateRunnerLogic.swift
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

extension ProcessBlock {

    init?<T>(stateRunnerLogicFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard
            machine.drivingClock < machine.clocks.count,
            machine.drivingClock >= 0,
            let statement = CaseStatement(stateRunnerLogicFor: state, in: representation)
        else {
            return nil
        }
        let clock = machine.clocks[machine.drivingClock].name
        self.init(
            sensitivityList: [clock],
            code: .ifStatement(block: IfBlock.ifStatement(
                condition: .conditional(condition: .edge(value: .rising(expression: .reference(
                    variable: .variable(reference: .variable(name: clock))
                )))),
                ifBlock: .caseStatement(block: statement)
            ))
        )
    }

}

extension CaseStatement {

    init?<T>(stateRunnerLogicFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        guard
            let initial = WhenCase(stateRunnerInitialFor: representation),
            let waitToStart = WhenCase(stateRunnerWaitToStartFor: state, in: representation)
        else {
            return nil
        }
        self.init(
            condition: .reference(variable: .variable(reference: .variable(name: .internalState))),
            cases: [initial, waitToStart, .startRunners, .waitForRunners, .waitForFinish, .othersNull]
        )
    }

}

extension WhenCase {

    @usableFromInline static let startRunners = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: VariableName(rawValue: "StartRunners")!
        )))),
        code: .statement(statement: .assignment(
            name: .variable(reference: .variable(name: .internalState)),
            value: .reference(variable: .variable(reference: .variable(
                name: VariableName(rawValue: "WaitForRunners")!
            )))
        ))
    )

    @usableFromInline static let waitForFinish = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: .waitForFinish
        )))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .reset)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitToStart)))
            ))
        ])
    )

    @usableFromInline static let waitForRunners = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(reference: .variable(
            name: VariableName(rawValue: "WaitForRunners")!
        )))),
        code: .ifStatement(block: .ifStatement(
            condition: .reference(variable: .indexed(
                name: .reference(variable: .variable(reference: .variable(name: .finished))),
                index: .index(value: .literal(value: .integer(value: 0)))
            )),
            ifBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .reset)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .internalState)),
                    value: .reference(variable: .variable(reference: .variable(name: .waitForFinish)))
                ))
            ])
        ))
    )

    init?<T>(stateRunnerInitialFor representation: T) where T: MachineVHDLRepresentable {
        guard let stateSize = representation.numberOfStateBits else {
            return nil
        }
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: VariableName(rawValue: "Initial")!)
            ))),
            code: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .hasStarted)),
                    value: .literal(value: .boolean(value: false))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .internalState)),
                    value: .reference(variable: .variable(reference: .variable(name: .waitToStart)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .reset)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .previousRinglet)),
                    value: .literal(value: .vector(value: .logics(
                        value: LogicVector(
                            values: [LogicLiteral](repeating: .highImpedance, count: stateSize)
                        )
                    )))
                ))
            ])
        )
    }

    init?<T>(stateRunnerWaitToStartFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        guard let numberOfStateBits = representation.numberOfStateBits else {
            return nil
        }
        let machine = representation.machine
        let validExternals = Set(state.externalVariables)
        let workingVariables: [VariableName] = machine.externalSignals.filter {
            $0.mode != .input && validExternals.contains($0.name)
        }
        .map(\.name) + machine.externalSignals.filter {
            $0.mode != .input && !validExternals.contains($0.name)
        }
        .map {
            VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)")!
        } + machine.machineSignals.map {
            VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)")!
        } + machine.stateVariables.values.flatMap {
            $0.map {
                VariableName(
                    rawValue: "\(machine.name.rawValue)_STATE_\(state.name.rawValue)_\($0.name.rawValue)"
                )!
            }
        }
        let assignments: [(VariableName, VariableName)] = [
            (VariableName(rawValue: "current_ExecuteOnEntry")!, VariableName.executeOnEntry),
            (VariableName(rawValue: "working_ExecuteOnEntry")!, VariableName.executeOnEntry)
        ] + workingVariables.flatMap {
            [
                (VariableName(rawValue: "current_\($0)")!, $0),
                (VariableName(rawValue: "working_\($0)")!, $0)
            ]
        }
        let statements = assignments.map {
            SynchronousBlock.statement(statement: Statement.assignment(
                name: .variable(reference: .variable(name: $0)),
                value: .reference(variable: .variable(reference: .variable(name: $1)))
            ))
        }
        let comparisons = ([VariableName.executeOnEntry] + workingVariables).map {
            Expression.conditional(condition: .comparison(value: .notEquals(
                lhs: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "current_\($0)")!
                ))),
                rhs: .reference(variable: .variable(reference: .variable(name: $0)))
            )))
        }
        .joined { Expression.logical(operation: .or(lhs: $0, rhs: $1)) }
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .waitToStart)
            ))),
            code: .ifStatement(block: .ifElse(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                ifBlock: .ifStatement(block: .ifElse(
                    condition: .logical(operation: .or(
                        lhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .hasStarted))),
                            rhs: .literal(value: .boolean(value: false))
                        ))),
                        rhs: comparisons
                    )),
                    ifBlock: .blocks(
                        blocks: [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .hasStarted)),
                                value: .literal(value: .boolean(value: true))
                            ))
                        ] + statements + [
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .internalState)),
                                value: .reference(variable: .variable(
                                    reference: .variable(name: VariableName(rawValue: "StartRunners")!)
                                ))
                            )),
                            .ifStatement(block: .ifElse(
                                condition: .reference(variable: .variable(
                                    reference: .variable(name: .executeOnEntry)
                                )),
                                ifBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .previousRinglet)),
                                    value: .literal(value: .vector(value: .logics(value: LogicVector(
                                        values: [LogicLiteral](
                                            repeating: .highImpedance, count: numberOfStateBits
                                        )
                                    ))))
                                )),
                                elseBlock: .statement(statement: .assignment(
                                    name: .variable(reference: .variable(name: .previousRinglet)),
                                    value: .reference(variable: .variable(reference: .variable(
                                        name: VariableName(rawValue: "STATE_\(state.name.rawValue)")!
                                    )))
                                ))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .busy)),
                                value: .literal(value: .bit(value: .high))
                            )),
                            .statement(statement: .assignment(
                                name: .variable(reference: .variable(name: .reset)),
                                value: .literal(value: .bit(value: .high))
                            ))
                        ]
                    ),
                    elseBlock: .blocks(blocks: [
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .busy)),
                            value: .literal(value: .bit(value: .low))
                        )),
                        .statement(statement: .assignment(
                            name: .variable(reference: .variable(name: .reset)),
                            value: .literal(value: .bit(value: .low))
                        ))
                    ])
                )),
                elseBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .low))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .reset)),
                        value: .literal(value: .bit(value: .low))
                    ))
                ])
            ))
        )
    }

}
