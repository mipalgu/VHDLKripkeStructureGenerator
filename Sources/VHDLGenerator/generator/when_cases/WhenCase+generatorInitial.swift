// WhenCase+generatorInitial.swift
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

extension WhenCase {

    init?<T>(generatorInitialFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let initialState = machine.states[machine.initialState]
        guard let writeSnapshot = Record(writeSnapshotFor: initialState, in: representation) else {
            return nil
        }
        let literals: [LogicLiteral] = writeSnapshot.types.flatMap {
            guard $0.name != .nextState else {
                return BitLiteral.bitVersion(
                    of: machine.initialState, bitsRequired: machine.numberOfStateBits
                )
                .map {
                    LogicLiteral(bit: $0)
                }
            }
            guard $0.name != .executeOnEntry else {
                return [.high]
            }
            return $0.type.signalType.defaultEncoding
        } + [.high]
        let stateSignals = machine.states.flatMap {
            let name = $0.name.rawValue
            let writeSnapshot = Record(writeSnapshotFor: $0, in: representation)!
            let types = writeSnapshot.types.filter { $0.name != .nextState }
            return types.map {
                SynchronousBlock.statement(statement: .assignment(
                    name: .variable(reference: .variable(
                        name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                    )),
                    value: .literal(value: $0.type.signalType.defaultValue)
                ))
            } + [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(rawValue: "\(name)Ready")!)),
                    value: .literal(value: .bit(value: .low))
                ))
            ]
        }
        let stateWorking = machine.states.map {
            SynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(
                    name: VariableName(rawValue: "\($0.name.rawValue)Working")!
                )),
                value: .literal(value: .boolean(value: false))
            ))
        }
        let defaultAssignments: [SynchronousBlock] = [
            .statement(statement: .assignment(
                name: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .pendingStates))),
                    index: .index(value: .literal(value: .integer(value: 0)))
                ),
                value: .literal(value: .vector(value: .logics(value: LogicVector(values: literals))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .finished)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .pendingStateIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .observedIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .nextState)),
                value: .reference(variable: .variable(reference: .variable(name: .initial)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .isDuplicate)),
                value: .literal(value: .boolean(value: false))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .isFinished)),
                value: .literal(value: .boolean(value: false))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .pendingInsertIndex)),
                value: .literal(value: .integer(value: 1))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .maxInsertIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .fromState)),
                value: .reference(variable: .variable(reference: .variable(name: .setJob)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentState)),
                value: .reference(variable: .variable(reference: .variable(name: .setJob)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .observedSearchIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .pendingSearchIndex)),
                value: .literal(value: .integer(value: 0))
            ))
        ]
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .initial)
            ))),
            code: .blocks(blocks: defaultAssignments + stateSignals + stateWorking)
        )
    }

    init?<T>(sequentialGeneratorInitialFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let initialState = machine.states[machine.initialState]
        guard let writeSnapshot = Record(writeSnapshotFor: initialState, in: representation) else {
            return nil
        }
        let literals: [LogicLiteral] = writeSnapshot.types.flatMap {
            guard $0.name != .nextState else {
                return BitLiteral.bitVersion(
                    of: machine.initialState, bitsRequired: machine.numberOfStateBits
                )
                .map {
                    LogicLiteral(bit: $0)
                }
            }
            guard $0.name != .executeOnEntry else {
                return [.high]
            }
            return $0.type.signalType.defaultEncoding
        }
        let stateSignals = machine.states.flatMap {
            let name = $0.name.rawValue
            let writeSnapshot = Record(writeSnapshotFor: $0, in: representation)!
            let types = writeSnapshot.types.filter { $0.name != .nextState }
            return types.map {
                SynchronousBlock.statement(statement: .assignment(
                    name: .variable(reference: .variable(
                        name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                    )),
                    value: .literal(value: $0.type.signalType.defaultValue)
                ))
            } + [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(rawValue: "\(name)Ready")!)),
                    value: .literal(value: .bit(value: .low))
                ))
            ]
        }
        let defaultAssignments: [SynchronousBlock] = [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .targetStatesData0)),
                value: .literal(value: .vector(value: .logics(value: LogicVector(values: literals))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentTargetState)),
                value: .literal(value: .vector(value: .logics(value: LogicVector(values: literals))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .targetStatesWe0)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .targetStatesReady0)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .finished)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .pendingStateIndex)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            ))
        ]
        let internalState = [
            SynchronousBlock.ifStatement(block: .ifStatement(
                condition: .conditional(condition: .comparison(value: .equality(
                    lhs: .reference(variable: .variable(reference: .variable(name: .targetStatesEn0))),
                    rhs: .literal(value: .bit(value: .high))
                ))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(reference: .variable(name: .resetRead)))
                ))
            ))
        ]
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .initial)
            ))),
            code: .blocks(blocks: defaultAssignments + stateSignals + internalState)
        )
    }

}

extension SignalType {

    var defaultEncoding: [LogicLiteral] {
        [LogicLiteral](repeating: .low, count: self.bits)
    }

}
