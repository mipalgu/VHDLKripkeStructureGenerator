// AsynchronousBlock+bramInterface.swift
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

    init<T>(bramInterfaceFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let stateAssignments = machine.states.enumerated().flatMap {
            let name = $1.name.rawValue
            let unsignedLastAddress = VariableName(rawValue: "unsigned\(name)LastAddress")!
            let lastAddress = VariableName(rawValue: "\(name)LastAddress")!
            let address = VariableName(rawValue: "\(name)Address")!
            let isState = VariableName(rawValue: "is\(name)")!
            let read = VariableName(rawValue: "\(name)Read")!
            let isPreviousState = VariableName(rawValue: "isPrevious\(name)")!
            let ready = VariableName(rawValue: "\(name)ReadReady")!
            guard $0 != 0 else {
                return [
                    AsynchronousBlock.statement(statement: .assignment(
                        name: .variable(reference: .variable(name: unsignedLastAddress)),
                        value: .expression(value: .cast(operation: .unsigned(expression: .reference(
                            variable: .variable(reference: .variable(name: lastAddress))
                        ))))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: isState)),
                        value: .expression(value: .logical(operation: .and(
                            lhs: .conditional(condition: .comparison(value: .lessThanOrEqual(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .unsignedAddress)
                                )),
                                rhs: .reference(variable: .variable(reference: .variable(
                                    name: unsignedLastAddress
                                )))
                            ))),
                            rhs: .conditional(condition: .comparison(value: .equality(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .generatorFinished)
                                )),
                                rhs: .literal(value: .bit(value: .high))
                            )))
                        )))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: address)),
                        value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                            value: .reference(variable: .variable(reference: .variable(name: .address))),
                            condition: .reference(variable: .variable(reference: .variable(name: isState))),
                            elseBlock: .expression(value: .literal(value: .vector(value: .indexed(
                                values: IndexedVector(
                                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                                )
                            ))))
                        )))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: read)),
                        value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                            value: .reference(variable: .variable(reference: .variable(name: .read))),
                            condition: .logical(operation: .or(
                                lhs: .reference(variable: .variable(reference: .variable(name: isState))),
                                rhs: .reference(variable: .variable(
                                    reference: .variable(name: isPreviousState)
                                ))
                            )),
                            elseBlock: .expression(value: .literal(value: .bit(value: .low)))
                        )))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: ready)),
                        value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                            value: .reference(variable: .variable(reference: .variable(name: .ready))),
                            condition: .logical(operation: .or(
                                lhs: .reference(variable: .variable(reference: .variable(name: isState))),
                                rhs: .reference(variable: .variable(
                                    reference: .variable(name: isPreviousState)
                                ))
                            )),
                            elseBlock: .expression(value: .literal(value: .bit(value: .low)))
                        )))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: isPreviousState)),
                        value: .expression(value: .logical(operation: .and(
                            lhs: .conditional(condition: .comparison(value: .lessThanOrEqual(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .previousAddress)
                                )),
                                rhs: .reference(variable: .variable(
                                    reference: .variable(name: unsignedLastAddress)
                                ))
                            ))),
                            rhs: .conditional(condition: .comparison(value: .equality(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .generatorFinished)
                                )),
                                rhs: .literal(value: .bit(value: .high))
                            )))
                        )))
                    ))
                ]
            }
            let previousStateName = machine.states[$0 - 1].name
            let previousUnsignedStateLastAddress = VariableName(
                rawValue: "unsigned\(previousStateName)LastAddress"
            )!
            return [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: unsignedLastAddress)),
                    value: .expression(value: .binary(operation: .addition(
                        lhs: .binary(operation: .addition(
                            lhs: .cast(operation: .unsigned(expression: .reference(variable: .variable(
                                reference: .variable(name: lastAddress)
                            )))),
                            rhs: .reference(variable: .variable(reference: .variable(
                                name: previousUnsignedStateLastAddress
                            )))
                        )),
                        rhs: .literal(value: .integer(value: 1))
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: isState)),
                    value: .expression(value: .logical(operation: .and(
                        lhs: .logical(operation: .and(
                            lhs: .conditional(condition: .comparison(value: .greaterThan(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .unsignedAddress)
                                )),
                                rhs: .reference(variable: .variable(reference: .variable(
                                    name: previousUnsignedStateLastAddress
                                )))
                            ))),
                            rhs: .conditional(condition: .comparison(value: .lessThanOrEqual(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .unsignedAddress)
                                )),
                                rhs: .reference(variable: .variable(
                                    reference: .variable(name: unsignedLastAddress)
                                ))
                            )))
                        )),
                        rhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(
                                reference: .variable(name: .generatorFinished)
                            )),
                            rhs: .literal(value: .bit(value: .high))
                        )))
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: address)),
                    value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                        value: .cast(operation: .stdLogicVector(expression: .binary(
                            operation: .subtraction(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .unsignedAddress)
                                )),
                                rhs: .precedence(value: .binary(operation: .addition(
                                    lhs: .literal(value: .integer(value: 1)),
                                    rhs: .reference(variable: .variable(
                                        reference: .variable(name: previousUnsignedStateLastAddress)
                                    ))
                                )))
                            )
                        ))),
                        condition: .reference(variable: .variable(reference: .variable(name: isState))),
                        elseBlock: .expression(value: .literal(value: .vector(value: .indexed(
                            values: IndexedVector(
                                values: [IndexedValue(index: .others, value: .bit(value: .low))]
                            )
                        ))))
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: read)),
                    value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                        value: .reference(variable: .variable(reference: .variable(name: .read))),
                        condition: .logical(operation: .or(
                            lhs: .reference(variable: .variable(reference: .variable(name: isState))),
                            rhs: .reference(variable: .variable(
                                reference: .variable(name: isPreviousState)
                            ))
                        )),
                        elseBlock: .expression(value: .literal(value: .bit(value: .low)))
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: ready)),
                    value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                        value: .reference(variable: .variable(reference: .variable(name: .ready))),
                        condition: .logical(operation: .or(
                            lhs: .reference(variable: .variable(reference: .variable(name: isState))),
                            rhs: .reference(variable: .variable(
                                reference: .variable(name: isPreviousState)
                            ))
                        )),
                        elseBlock: .expression(value: .literal(value: .bit(value: .low)))
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: isPreviousState)),
                    value: .expression(value: .logical(operation: .and(
                        lhs: .logical(operation: .and(
                            lhs: .conditional(condition: .comparison(value: .greaterThan(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .previousAddress)
                                )),
                                rhs: .reference(variable: .variable(reference: .variable(
                                    name: previousUnsignedStateLastAddress
                                )))
                            ))),
                            rhs: .conditional(condition: .comparison(value: .lessThanOrEqual(
                                lhs: .reference(variable: .variable(
                                    reference: .variable(name: .previousAddress)
                                )),
                                rhs: .reference(variable: .variable(
                                    reference: .variable(name: unsignedLastAddress)
                                ))
                            )))
                        )),
                        rhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(
                                reference: .variable(name: .generatorFinished)
                            )),
                            rhs: .literal(value: .bit(value: .high))
                        )))
                    )))
                ))
            ]
        }
        let stateValues = machine.states.map {
            let name = $0.name.rawValue
            return AsynchronousExpression.whenBlock(value: .when(statement: WhenStatement(
                condition: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "isPrevious\(name)")!
                ))),
                value: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "\(name)Value")!
                )))
            )))
        }
        let trailer = AsynchronousExpression.expression(value: .literal(value: .vector(value: .indexed(
            values: IndexedVector(values: [IndexedValue(index: .others, value: .bit(value: .low))])
        ))))
        let whenStatement = (stateValues + [trailer]).reversed().joined {
            guard case .whenBlock(let block) = $1, case .when(let statement) = block else {
                fatalError("Invalid syntax in state values for data assignment in BRAM interface!")
            }
            return AsynchronousExpression.whenBlock(value: .whenElse(statement: WhenElseStatement(
                value: statement.value,
                condition: statement.condition,
                elseBlock: $0
            )))
        }
        let generatorEntity = Entity(generatorFor: representation)
        let mappings = generatorEntity.port.signals.map {
            guard $0.name != .finished else {
                return VariableMap(
                    lhs: .variable(reference: .variable(name: .finished)),
                    rhs: .expression(value: .reference(variable: .variable(
                        reference: .variable(name: .generatorFinished)
                    )))
                )
            }
            return VariableMap(
                lhs: .variable(reference: .variable(name: $0.name)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: $0.name))))
            )
        }
        let component = ComponentInstantiation(
            label: VariableName(rawValue: "gen_inst")!,
            name: generatorEntity.name,
            port: PortMap(variables: mappings)
        )
        self = .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .unsignedAddress)),
                value: .expression(value: .cast(operation: .unsigned(expression: .reference(
                    variable: .variable(reference: .variable(name: .address))
                ))))
            ))
        ] + stateAssignments + [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .data)),
                value: whenStatement
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .finished)),
                value: .expression(value: .reference(variable: .variable(
                    reference: .variable(name: .generatorFinished)
                )))
            )),
            .component(block: component),
            .process(block: ProcessBlock(bramInterfaceFor: representation))
        ])
    }

}

extension ProcessBlock {

    init<T>(bramInterfaceFor representation: T) where T: MachineVHDLRepresentable {
        let clk = representation.machine.clocks[representation.machine.drivingClock].name
        self.init(
            sensitivityList: [clk],
            code: .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .edge(value: .rising(expression: .reference(
                    variable: .variable(reference: .variable(name: clk))
                )))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .previousAddress)),
                    value: .cast(operation: .unsigned(expression: .reference(variable: .variable(
                        reference: .variable(name: .address)
                    ))))
                ))
            ))
        )
    }

}
