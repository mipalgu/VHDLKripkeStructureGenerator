// AsynchronousBlock+ringletExpander.swift
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
import VHDLParsing

/// Add ringlet expander.
extension AsynchronousBlock {

    /// Create the ringlet expander logic for a state.
    /// - Parameters:
    ///   - state: The state to create the ringlet expander logic for.
    ///   - representation: The representation of the machine to use.
    @inlinable
    init?<T>(ringletExpanderFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        guard let write = Record(writeSnapshotFor: state, in: representation) else {
            return nil
        }
        let read = Record(readSnapshotFor: state, in: representation)
        let readTypes = read.types.filter { $0.name != .executeOnEntry }
        let readOnEntry = Expression(boolToStdLogicForSnapshot: .readSnapshotSignal)
        let readExpression = Expression(
            concatenate: readTypes, appending: readOnEntry, record: .readSnapshotSignal
        )
        let writeTypes = write.types.filter { $0.name != .executeOnEntry && $0.name != .nextState }
        let writeNextState = Expression.reference(variable: .variable(reference: .member(
            access: MemberAccess(record: .ringlet, member: .member(access: MemberAccess(
                record: .writeSnapshotSignal, member: .variable(name: .nextState)
            )))
        )))
        let writeOnEntry = Expression(boolToStdLogicForSnapshot: .writeSnapshotSignal)
        let writeExpression = Expression(
            concatenate: writeTypes,
            appending: [writeNextState, writeOnEntry].concatenated,
            record: .writeSnapshotSignal
        )
        let observed = Expression.functionCall(call: .custom(function: CustomFunctionCall(
            name: .boolToStdLogic,
            parameters: [
                Argument(argument: .reference(variable: .variable(reference: .member(access: MemberAccess(
                    record: .ringlet, member: .variable(name: .observed)
                )))))
            ]
        )))
        let expression = Expression.binary(operation: .concatenate(
            lhs: .binary(operation: .concatenate(lhs: readExpression, rhs: writeExpression)), rhs: observed
        ))
        self = .statement(statement: .assignment(
            name: .variable(reference: .variable(name: .vector)),
            value: .expression(value: expression)
        ))
    }

}

/// Add helper functions.
extension Expression {

    /// Helper function to concatenate types in the ringlet expander.
    /// - Parameters:
    ///   - types: The types to concatenate.
    ///   - expression: Any expression to append to the end of the concatenated types.
    ///   - record: The record name to prepend to the types.
    @inlinable
    init(concatenate types: [RecordTypeDeclaration], appending expression: Expression, record: VariableName) {
        let result: Expression
        if types.isEmpty {
            result = expression
        } else {
            let snapshotExpression = types.dropFirst().reduce(
                Expression(
                    encodeType: types[0].type,
                    name: .reference(variable: .variable(
                        reference: .member(access: MemberAccess(
                            record: .ringlet,
                            member: .member(
                                access: MemberAccess(record: record, member: .variable(name: types[0].name))
                            )
                        ))
                    ))
                )
            ) {
                Expression.binary(operation: .concatenate(
                    lhs: $0,
                    rhs: Expression(encodeType: $1.type, name: .reference(
                        variable: .variable(reference: .member(access: MemberAccess(
                            record: .ringlet, member: .member(access: MemberAccess(
                                record: record, member: .variable(name: $1.name)
                            ))
                        )))
                    ))
                ))
            }
            result = .binary(operation: .concatenate(lhs: snapshotExpression, rhs: expression))
        }
        self = result
    }

    /// Create a boolToStdLogic invocation with parameter `snapshot`.
    /// - Parameter snapshot: The snapshot to use as the parameter.
    @inlinable
    init(boolToStdLogicForSnapshot snapshot: VariableName) {
        self = .functionCall(call: .custom(function: CustomFunctionCall(
            name: .boolToStdLogic,
            parameters: [
                Argument(argument: .reference(variable: .variable(reference: .member(access: MemberAccess(
                    record: .ringlet,
                    member: .member(access: MemberAccess(
                        record: snapshot, member: .variable(name: .executeOnEntry)
                    ))
                )))))
            ]
        )))
    }

    /// Create an encoded invocation.
    /// - Parameters:
    ///   - type: The type to encode.
    ///   - name: The name of the variable to encode.
    @inlinable
    init(encodeType type: Type, name: Expression) {
        guard case .signal(let type) = type else {
            fatalError("Failed to convert type \(type)!")
        }
        switch type {
        case .bit:
            self = .cast(operation: .stdLogic(expression: name))
        case .boolean:
            self = .functionCall(call: .custom(function: CustomFunctionCall(
                name: .boolToStdLogic,
                parameters: [Argument(argument: name)]
            )))
        case .natural, .positive:
            self = .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                function: CustomFunctionCall(
                    name: .toUnsigned,
                    parameters: [
                        Argument(argument: name),
                        Argument(argument: .literal(value: .integer(value: type.encodedBits)))
                    ]
                )
            ))))
        case .integer:
            self = .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                function: CustomFunctionCall(
                    name: .toSigned,
                    parameters: [
                        Argument(argument: name),
                        Argument(argument: .literal(value: .integer(value: type.encodedBits)))
                    ]
                )
            ))))
        case .stdLogic:
            self = .functionCall(call: .custom(function: CustomFunctionCall(
                name: .stdLogicEncoded, parameters: [Argument(argument: name)]
            )))
        case .stdULogic:
            self = .functionCall(call: .custom(function: CustomFunctionCall(
                name: .stdULogicEncoded, parameters: [Argument(argument: name)]
            )))
        case .ranged(let ranged):
            self.init(encodedType: ranged, name: name)
        default:
            fatalError("Using unsupported type for kripke structure generator \(type)!")
        }
    }

    // swiftlint:disable function_body_length

    /// Create an encoded function invocation for a ranged type.
    /// - Parameters:
    ///   - ranged: The type to encode.
    ///   - name: The name of the variable to encode.
    @inlinable
    init(encodedType ranged: RangedType, name: Expression) {
        switch ranged {
        case .bitVector:
            self = .cast(operation: .stdLogicVector(expression: name))
        case .integer(let size):
            guard case .literal(let literal) = size.min, case .integer(let min) = literal, min >= 0 else {
                self = .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                    function: CustomFunctionCall(
                        name: .toSigned,
                        parameters: [
                            Argument(argument: name),
                            Argument(argument: .literal(value: .integer(value: ranged.encodedBits)))
                        ]
                    )
                ))))
                return
            }
            self = .cast(operation: .stdLogicVector(expression: .functionCall(call: .custom(
                function: CustomFunctionCall(
                    name: .toUnsigned,
                    parameters: [
                        Argument(argument: name),
                        Argument(argument: .literal(value: .integer(value: ranged.encodedBits)))
                    ]
                )
            ))))
            return
        case .signed, .unsigned:
            self = .cast(operation: .stdLogicVector(expression: name))
        case .stdLogicVector(let size):
            let bits = ranged.bits
            let fn: (Int) -> Expression = {
                Expression.functionCall(call: .custom(function: CustomFunctionCall(
                    name: .stdLogicEncoded,
                    parameters: [
                        Argument(argument: .reference(variable: .indexed(name: name, index: .index(
                            value: .literal(value: .integer(value: $0))
                        ))))
                    ]
                )))
            }
            switch size {
            case .downto:
                self = (0...(bits - 1)).reversed().map(fn).concatenated
            case .to:
                self = (0...(bits - 1)).map(fn).concatenated
            }
        case .stdULogicVector(let size):
            let bits = ranged.bits
            let bitRange: ClosedRange<Int>
            switch size {
            case .downto:
                bitRange = (bits - 1)...0
            case .to:
                bitRange = 0...(bits - 1)
            }
            self = bitRange.map {
                Expression.functionCall(call: .custom(function: CustomFunctionCall(
                    name: .stdULogicEncoded,
                    parameters: [
                        Argument(argument: .reference(variable: .indexed(name: name, index: .index(
                            value: .literal(value: .integer(value: $0))
                        ))))
                    ]
                )))
            }
            .concatenated
        }
    }

    // swiftlint:enable function_body_length

}
