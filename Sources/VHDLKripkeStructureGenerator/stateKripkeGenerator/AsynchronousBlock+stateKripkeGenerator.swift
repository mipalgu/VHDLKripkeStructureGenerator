// AsynchronousBlock+stateGenerator.swift
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

/// Add state kripke generator.
extension AsynchronousBlock {

    // swiftlint:disable function_body_length

    /// Creates the logic for a states kripke generator. This logic expands a states read and write snapshots
    /// into the next state to compute.
    /// - Parameters:
    ///   - state: The state to generate this logic for.
    ///   - representation: The machine representation the `state` belongs to.
    @inlinable
    init?<T>(stateKripkeGeneratorFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard
            machine.drivingClock >= 0,
            machine.drivingClock < machine.clocks.count,
            let writeRecord = Record(writeSnapshotFor: state, in: representation)
        else {
            return nil
        }
        let externals = Set(machine.externalSignals.map(\.name))
        let clock = machine.clocks[machine.drivingClock].name
        let readSnapshot = Record(readSnapshotFor: state, in: representation).types.map {
            IndexedValue(
                index: .index(value: .reference(variable: .variable(reference: .variable(name: $0.name)))),
                value: .reference(variable: .variable(reference: .member(access: MemberAccess(
                    record: .readSnapshotSignal, member: .variable(name: $0.name)
                ))))
            )
        }
        let writeSnapshot = writeRecord.types.map {
            let name = $0.name.rawValue
            guard !name.hasPrefix(representation.entity.name.rawValue) else {
                let withoutPrefix = name.dropFirst(representation.entity.name.rawValue.count + 1)
                let newName = VariableName(rawValue: String(withoutPrefix))!
                guard !externals.contains(newName) else {
                    return IndexedValue(
                        index: .index(value: .reference(variable: .variable(
                            reference: .variable(name: $0.name)
                        ))),
                        value: .reference(variable: .variable(reference: .member(access: MemberAccess(
                            record: .writeSnapshotSignal, member: .variable(name: newName)
                        ))))
                    )
                }
                return IndexedValue(
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: $0.name)
                    ))),
                    value: .reference(variable: .variable(reference: .member(access: MemberAccess(
                        record: .writeSnapshotSignal, member: .variable(name: $0.name)
                    ))))
                )
            }
            return IndexedValue(
                index: .index(value: .reference(variable: .variable(reference: .variable(name: $0.name)))),
                value: .reference(variable: .variable(reference: .member(access: MemberAccess(
                    record: .writeSnapshotSignal, member: .variable(name: $0.name)
                ))))
            )
        }
        let ringlet = Statement.assignment(
            name: .variable(reference: .variable(name: .ringlet)),
            value: .literal(value: .vector(value: .indexed(values: IndexedVector(values: [
                IndexedValue(
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .readSnapshotSignal)
                    ))),
                    value: .literal(value: .vector(value: .indexed(
                        values: IndexedVector(values: readSnapshot)
                    )))
                ),
                IndexedValue(
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .writeSnapshotSignal)
                    ))),
                    value: .literal(value: .vector(value: .indexed(
                        values: IndexedVector(values: writeSnapshot)
                    )))
                ),
                IndexedValue(
                    index: .index(value: .reference(variable: .variable(
                        reference: .variable(name: .observed)
                    ))),
                    value: .boolean(value: true)
                )
            ]))))
        )
        let writeSignals = writeRecord.types.filter { $0.name != .nextState && $0.name != .executeOnEntry }
        let joinedSignals = writeSignals.reduce(Expression.reference(variable: .variable(
            reference: .member(access: MemberAccess(
                record: .writeSnapshotSignal, member: .variable(name: .nextState)
            ))
        ))) {
            let name = $1.name.rawValue
            guard !name.hasPrefix(representation.entity.name.rawValue) else {
                let withoutPrefix = name.dropFirst(representation.entity.name.rawValue.count + 1)
                let newName = VariableName(rawValue: String(withoutPrefix))!
                guard !externals.contains(newName) else {
                    return Expression.binary(operation: .concatenate(
                        lhs: $0,
                        rhs: $1.type.signalType.conversion(value: .reference(variable: .variable(
                            reference: .member(access: MemberAccess(
                                record: .writeSnapshotSignal, member: .variable(name: newName)
                            ))
                        )))
                    ))
                }
                return Expression.binary(operation: .concatenate(
                    lhs: $0,
                    rhs: $1.type.signalType.conversion(value: .reference(variable: .variable(
                        reference: .member(access: MemberAccess(
                            record: .writeSnapshotSignal, member: .variable(name: $1.name)
                        ))
                    )))
                ))
            }
            return Expression.binary(operation: .concatenate(
                lhs: $0,
                rhs: $1.type.signalType.conversion(value: .reference(variable: .variable(
                    reference: .member(access: MemberAccess(
                        record: .writeSnapshotSignal, member: .variable(name: $1.name)
                    ))
                )))
            ))
        }
        let allJoined = Expression.binary(operation: .concatenate(
            lhs: .binary(operation: .concatenate(
                lhs: joinedSignals,
                rhs: .functionCall(call: FunctionCall.custom(function: CustomFunctionCall(
                    name: .boolToStdLogic,
                    parameters: [
                        Argument(argument: .reference(variable: .variable(
                            reference: .member(access: MemberAccess(
                                record: .writeSnapshotSignal, member: .variable(name: .executeOnEntry)
                            ))
                        )))
                    ]
                )))
            )),
            rhs: .literal(value: .bit(value: .high))
        ))
        let process = ProcessBlock(
            sensitivityList: [clock],
            code: .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .edge(value: .rising(expression: .reference(
                    variable: .variable(reference: .variable(name: clock))
                )))),
                ifBlock: .blocks(blocks: [
                    .statement(statement: ringlet),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .pendingState)), value: allJoined
                    ))
                ])
            ))
        )
        self = .process(block: process)
    }

    // swiftlint:enable function_body_length

}
