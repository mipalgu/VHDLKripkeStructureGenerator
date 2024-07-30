// AsynchronousBlock+cache.swift
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

import Foundation
import Utilities
import VHDLParsing

/// Add cache creation.
extension AsynchronousBlock {

    // swiftlint:disable function_body_length
    // swiftlint:disable force_unwrapping

    /// Generate a cache.
    @inlinable
    init?(cacheName name: VariableName, elementSize size: Int, numberOfElements: Int) {
        guard size <= 30 else {
            fatalError("Caches containing large elements are not yet supported!")
        }
        guard
            size > 0,
            numberOfElements > 0,
            let process = ProcessBlock(
                cacheName: name, elementSize: size, numberOfElements: numberOfElements
            ),
            let decoder = VariableName(rawValue: name.rawValue + "Decoder"),
            let decoderInst = VariableName(rawValue: decoder.rawValue + "_inst"),
            let encoder = VariableName(rawValue: name.rawValue + "Encoder"),
            let encoderInst = VariableName(rawValue: encoder.rawValue + "_inst"),
            let divider = VariableName(rawValue: name.rawValue + "Divider"),
            let dividerInst = VariableName(rawValue: divider.rawValue + "_inst"),
            let bram = VariableName(rawValue: name.rawValue + "BRAM"),
            let bramInst = VariableName(rawValue: bram.rawValue + "_inst")
        else {
            return nil
        }
        let encodedSize = size + 1
        let divisor = log2(Double(31 / encodedSize)).rounded(.down)
        let elementsPerAddress = Int(exp2(divisor).rounded())
        let addressBits = BitLiteral.bitsRequired(for: numberOfElements - 1) ?? 1
        guard addressBits <= 32 else {
            fatalError("The number of addresses in \(name.rawValue) exceeds a 32-bit resolution!")
        }
        let encoderMappings = (0..<elementsPerAddress).flatMap {
            [
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "in\($0)")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .cache))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "in\($0)en")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .enables))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                )
            ]
        }
        let encoderData = VariableMap(
            lhs: .variable(reference: .variable(name: .data)),
            rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: .di))))
        )
        let encoderInstantiation = AsynchronousBlock.component(block: ComponentInstantiation(
            label: encoderInst,
            name: encoder,
            port: PortMap(variables: encoderMappings + [encoderData])
        ))
        let decoderMappings = (0..<elementsPerAddress).flatMap {
            [
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "out\($0)")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .readCache))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: VariableName(rawValue: "out\($0)en")!)),
                    rhs: .expression(value: .reference(variable: .indexed(
                        name: .reference(variable: .variable(reference: .variable(name: .readEnables))),
                        index: .index(value: .literal(value: .integer(value: $0)))
                    )))
                )
            ]
        }
        let decoderData = VariableMap(
            lhs: .variable(reference: .variable(name: .data)),
            rhs: .expression(
                value: .reference(variable: .variable(reference: .variable(name: .currentValue)))
            )
        )
        let decoderInstantiation = AsynchronousBlock.component(block: ComponentInstantiation(
            label: decoderInst,
            name: decoder,
            port: PortMap(variables: [decoderData] + decoderMappings)
        ))
        let dividerMappings = [
            VariableMap(
                lhs: .variable(reference: .variable(name: .numerator)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .address))
                ))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .result)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .result))
                ))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .remainder)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .remainder))
                ))
            )
        ]
        let dividerInstantiation = AsynchronousBlock.component(block: ComponentInstantiation(
            label: dividerInst,
            name: divider,
            port: PortMap(variables: dividerMappings),
            generic: GenericMap(variables: [
                GenericVariableMap(
                    lhs: .variable(reference: .variable(name: .divisor)),
                    rhs: .literal(value: .integer(value: Int(divisor)))
                )
            ])
        ))
        let bramMappings = [
            VariableMap(
                lhs: .variable(reference: .variable(name: .clk)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .clk))
                ))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .we)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .weBRAM))
                ))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .addr)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .index))
                ))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .di)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .di))
                ))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .do)),
                rhs: .expression(value: .reference(
                    variable: .variable(reference: .variable(name: .currentValue))
                ))
            )
        ]
        let bramInstantiation = AsynchronousBlock.component(block: ComponentInstantiation(
            label: bramInst,
            name: bram,
            port: PortMap(variables: bramMappings)
        ))
        let components = [encoderInstantiation, decoderInstantiation, dividerInstantiation, bramInstantiation]
        let padding = 32 - addressBits
        let resultsCast = Expression.reference(variable: .variable(reference: .variable(name: .result)))
        let memoryAddress: Expression = padding == 0 ? resultsCast : .binary(operation: .concatenate(
            lhs: .literal(value: .vector(value: .bits(value: BitVector(
                values: [BitLiteral](repeating: .low, count: padding)
            )))),
            rhs: resultsCast
        ))
        let statements = [
            AsynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryAddress)),
                value: .expression(value: memoryAddress)
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .value)),
                value: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .readCache))),
                    index: .index(value: .functionCall(call: .custom(function: CustomFunctionCall(
                        name: .toInteger,
                        parameters: [
                            Argument(argument: .cast(operation: .unsigned(expression: .reference(
                                variable: .variable(reference: .variable(name: .remainder))
                            ))))
                        ]
                    ))))
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .valueEn)),
                value: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .readEnables))),
                    index: .index(value: .functionCall(call: .custom(function: CustomFunctionCall(
                        name: .toInteger,
                        parameters: [
                            Argument(argument: .cast(operation: .unsigned(expression: .reference(
                                variable: .variable(reference: .variable(name: .remainder))
                            ))))
                        ]
                    ))))
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
                                reference: .variable(name: .waitForNewDataType)
                            ))
                        )))
                    )),
                    elseBlock: .expression(
                        value: .reference(variable: .variable(reference: .variable(name: .genIndex)))
                    )
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .genIndex)),
                value: .expression(value: .cast(operation: .stdLogicVector(
                    expression: .functionCall(call: .custom(function: CustomFunctionCall(
                        name: .toUnsigned,
                        parameters: [
                            Argument(argument: .reference(
                                variable: .variable(reference: .variable(name: .memoryIndex))
                            )),
                            Argument(argument: .literal(value: .integer(value: 32)))
                        ]
                    )))
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .lastAddress)),
                value: .expression(value: .cast(operation: .stdLogicVector(
                    expression: .reference(
                        variable: .variable(reference: .variable(name: .unsignedLastAddress))
                    )
                )))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentIndex)),
                value: .expression(value: .binary(operation: .addition(
                    lhs: .functionCall(call: .custom(function: CustomFunctionCall(
                        name: .resize,
                        parameters: [
                            Argument(
                                argument: .binary(operation: .multiplication(
                                    lhs: .functionCall(call: .custom(function: CustomFunctionCall(
                                        name: .toUnsigned,
                                        parameters: [
                                            Argument(argument: .reference(
                                                variable: .variable(reference: .variable(name: .memoryIndex))
                                            )),
                                            Argument(argument: .literal(value: .integer(value: addressBits)))
                                        ]
                                    ))),
                                    rhs: .literal(value: .integer(value: elementsPerAddress))
                                ))
                            ),
                            Argument(argument: .literal(value: .integer(value: addressBits)))
                        ]
                    ))),
                    rhs: .functionCall(call: .custom(function: CustomFunctionCall(
                        name: .toUnsigned,
                        parameters: [
                            Argument(argument: .reference(
                                variable: .variable(reference: .variable(name: .cacheIndex))
                            )),
                            Argument(argument: .literal(value: .integer(value: addressBits)))
                        ]
                    )))
                )))
            ))
        ]
        self = .blocks(blocks: components + statements + [.process(block: process)])
    }

    // swiftlint:enable force_unwrapping
    // swiftlint:enable function_body_length

}
