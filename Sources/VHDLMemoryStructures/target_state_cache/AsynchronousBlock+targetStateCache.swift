// AsynchronousBlock+targetStateCache.swift
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
import VHDLMachines
import VHDLParsing

extension AsynchronousBlock {

    init?<T>(targetStatesCacheFor representation: T) where T: MachineVHDLRepresentable {
        guard
            let encoderInst = AsynchronousBlock(targetStatesCacheEncoderInstFor: representation),
            let decoderInst = AsynchronousBlock(targetStatesCacheDecoderInstFor: representation),
            let addressBits = BitLiteral.bitsRequired(for: representation.machine.numberOfTargetStates - 1),
            addressBits <= 32
        else {
            return nil
        }
        let bramInst = AsynchronousBlock(targetStatesCacheBRAMInstFor: representation)
        let padding = 32 - addressBits
        let addressCast = Expression.cast(operation: .stdLogicVector(expression: .binary(operation: .division(
            lhs: .cast(operation: .unsigned(expression: .reference(variable: .variable(
                reference: .variable(name: .address)
            )))),
            rhs: .literal(value: .integer(value: representation.targetStatesPerAddress))
        ))))
        let addressAssignment: Expression
        if padding > 0 {
            let paddingBits = Expression.literal(value: .vector(value: .bits(
                value: BitVector(values: [BitLiteral](repeating: .low, count: padding))
            )))
            addressAssignment = .binary(operation: .concatenate(lhs: paddingBits, rhs: addressCast))
        } else {
            addressAssignment = addressCast
        }
        self = .blocks(blocks: [
            bramInst,
            encoderInst,
            decoderInst,
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryAddress)),
                value: .expression(value: addressAssignment)
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryOffset)),
                value: .expression(value: .functionCall(call: .custom(function: CustomFunctionCall(
                    name: .toInteger,
                    parameters: [
                        Argument(argument: .binary(operation: .subtraction(
                            lhs: .cast(operation: .unsigned(expression: .reference(variable: .variable(
                                reference: .variable(name: .address)
                            )))),
                            rhs: .binary(operation: .multiplication(
                                lhs: .binary(operation: .division(
                                    lhs: .cast(operation: .unsigned(expression: .reference(
                                        variable: .variable(reference: .variable(name: .address))
                                    ))),
                                    rhs: .literal(value: .integer(
                                        value: representation.targetStatesPerAddress
                                    ))
                                )),
                                rhs: .literal(value: .integer(value: representation.targetStatesPerAddress))
                            ))
                        )))
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .value)),
                value: .expression(value: .binary(operation: .concatenate(
                    lhs: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .readStates))),
                        index: .index(value: .reference(variable: .variable(
                            reference: .variable(name: .memoryOffset)
                        )))
                    )),
                    rhs: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .readEnables))),
                        index: .index(value: .reference(variable: .variable(
                            reference: .variable(name: .memoryOffset)
                        )))
                    ))
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .index)),
                value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                    value: .reference(variable: .variable(reference: .variable(name: .memoryAddress))),
                    condition: .logical(operation: .and(
                        lhs: .logical(operation: .and(
                            lhs: .conditional(condition: .comparison(value: .equality(
                                lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                                rhs: .literal(value: .bit(value: .high))
                            ))),
                            rhs: .conditional(condition: .comparison(value: .notEquals(
                                lhs: .reference(variable: .variable(reference: .variable(name: .we))),
                                rhs: .literal(value: .bit(value: .high))
                            )))
                        )),
                        rhs: .conditional(condition: .comparison(value: .equality(
                            lhs: .reference(variable: .variable(reference: .variable(name: .internalState))),
                            rhs: .reference(variable: .variable(
                                reference: .variable(name: .waitForNewRinglets)
                            ))
                        )))
                    )),
                    elseBlock: .expression(value: .reference(variable: .variable(
                        reference: .variable(name: .genIndex)
                    )))
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .genIndex)),
                value: .expression(value: .cast(operation: .stdLogicVector(expression: .binary(
                    operation: .addition(
                        lhs: .binary(operation: .multiplication(
                            lhs: .functionCall(call: .custom(function: CustomFunctionCall(
                                name: .toUnsigned,
                                parameters: [
                                    Argument(argument: .reference(
                                        variable: .variable(reference: .variable(name: .memoryIndex))
                                    )),
                                    Argument(argument: .literal(value: .integer(value: addressBits)))
                                ]
                            ))),
                            rhs: .literal(value: .integer(value: representation.targetStatesPerAddress))
                        )),
                        rhs: .functionCall(call: .custom(function: CustomFunctionCall(
                            name: .toUnsigned,
                            parameters: [
                                Argument(argument: .reference(variable: .variable(
                                    reference: .variable(name: .stateIndex)
                                ))),
                                Argument(argument: .literal(value: .integer(value: addressBits)))
                            ]
                        )))
                    )
                ))))
            )),
            .process(block: ProcessBlock(targetStatesCacheFor: representation))
        ])
    }

    init<T>(targetStatesCacheBRAMInstFor representation: T) where T: MachineVHDLRepresentable {
        let bram = Entity(targetStatesBRAMFor: representation)
        let clock = representation.machine.clocks[representation.machine.drivingClock].name
        let bramMappings = [
            (clock, clock),
            (VariableName.we, VariableName.weBRAM),
            (VariableName.addr, VariableName.index),
            (VariableName.di, VariableName.di),
            (VariableName.do, VariableName.currentValue)
        ].map {
            VariableMap(
                lhs: .variable(reference: .variable(name: $0)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: $1))))
            )
        }
        let bramInst = ComponentInstantiation(
            label: VariableName(rawValue: "bram_inst")!,
            name: bram.name,
            port: PortMap(variables: bramMappings)
        )
        self = .component(block: bramInst)
    }

    init?<T>(targetStatesCacheDecoderInstFor representation: T) where T: MachineVHDLRepresentable {
        guard let decoder = Entity(targetStatesDecoderFor: representation) else {
            return nil
        }
        let dataMap = VariableMap(
            lhs: .variable(reference: .variable(name: .data)),
            rhs: .expression(value: .reference(
                variable: .variable(reference: .variable(name: .currentValue))
            ))
        )
        let mappings = (0..<representation.targetStatesPerAddress).flatMap {
            [
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "state\($0)")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .readStates))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "state\($0)en")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .readEnables))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                )
            ]
        }
        self = AsynchronousBlock.component(block: ComponentInstantiation(
            label: VariableName(rawValue: "decoder_inst")!,
            name: decoder.name,
            port: PortMap(variables: [dataMap] + mappings)
        ))
    }

    init?<T>(targetStatesCacheEncoderInstFor representation: T) where T: MachineVHDLRepresentable {
        guard let encoder = Entity(targetStatesEncoderFor: representation) else {
            return nil
        }
        let clock = representation.machine.clocks[representation.machine.drivingClock].name
        let clockMapping = VariableMap(
            lhs: .variable(reference: .variable(name: clock)),
            rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: clock))))
        )
        let mappings = (0..<representation.targetStatesPerAddress).flatMap {
            [
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "state\($0)")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .workingStates))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "state\($0)en")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .enables))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                )
            ]
        }
        let dataMap = VariableMap(
            lhs: .variable(reference: .variable(name: .data)),
            rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: .di))))
        )
        self = AsynchronousBlock.component(block: ComponentInstantiation(
            label: VariableName(rawValue: "encoder_inst")!,
            name: encoder.name,
            port: PortMap(variables: [clockMapping] + mappings + [dataMap])
        ))
    }

}
