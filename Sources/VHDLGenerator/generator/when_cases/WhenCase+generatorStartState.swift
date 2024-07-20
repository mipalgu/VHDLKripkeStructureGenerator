// WhenCase+generatorStartState.swift
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

    init<T>(generatorStartStateFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let name = state.name.rawValue
        let types = writeSnapshot.types.filter { $0.name != .nextState }
        let currentWorkingPendingState = Expression.reference(variable: .variable(reference: .variable(
            name: .currentWorkingPendingState
        )))
        let statements = types.map {
            let indexes = writeSnapshot.bitsIndex(for: $0.name, isDownto: true, adding: 1)!
            let value = Expression.reference(variable: .indexed(
                name: currentWorkingPendingState,
                index: indexes
            ))
            let bits = $0.type.bits
            guard bits <= 1 else {
                let type = SignalType.ranged(type: .stdLogicVector(
                    size: .downto(
                        upper: .literal(value: .integer(value: bits - 1)),
                        lower: .literal(value: .integer(value: 0))
                    )
                ))
                return SynchronousBlock.statement(statement: .assignment(
                    name: .variable(reference: .variable(
                        name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                    )),
                    value: type.conversion(value: value, to: $0.type.signalType)
                ))
            }
            return SynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(
                    name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                )),
                value: SignalType.stdLogic.conversion(value: value, to: $0.type.signalType)
            ))
        }
        self.init(
            condition: .expression(expression: .reference(variable: .variable(reference: .variable(
                name: VariableName(rawValue: "Start\(name)")!
            )))),
            code: .blocks(blocks: statements + [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(rawValue: "\(name)Ready")!)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "Reset\(name)Ready")!
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(rawValue: "\(name)Working")!)),
                    value: .literal(value: .boolean(value: true))
                ))
            ])
        )
    }

    init<T>(
        sequentialGeneratorStartStateFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let name = state.name.rawValue
        let types = writeSnapshot.types.filter { $0.name != .nextState }
        let statements = types.map {
            let indexes = writeSnapshot.bitsIndex(for: $0.name, isDownto: true, adding: 1)!
            let value = Expression.reference(variable: .indexed(
                name: .reference(variable: .variable(reference: .variable(name: .currentTargetState))),
                index: indexes
            ))
            let bits = $0.type.bits
            guard bits <= 1 else {
                let type = SignalType.ranged(type: .stdLogicVector(
                    size: .downto(
                        upper: .literal(value: .integer(value: bits - 1)),
                        lower: .literal(value: .integer(value: 0))
                    )
                ))
                return SynchronousBlock.statement(statement: .assignment(
                    name: .variable(reference: .variable(
                        name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                    )),
                    value: type.conversion(value: value, to: $0.type.signalType)
                ))
            }
            return SynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(
                    name: VariableName(rawValue: "\(name)\($0.name.rawValue)")!
                )),
                value: SignalType.stdLogic.conversion(value: value, to: $0.type.signalType)
            ))
        }
        self.init(
            condition: .expression(expression: .reference(variable: .variable(reference: .variable(
                name: VariableName(rawValue: "Start\(name)")!
            )))),
            code: .blocks(blocks: statements + [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(rawValue: "\(name)Ready")!)),
                    value: .literal(value: .bit(value: .high))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentState)),
                    value: .reference(variable: .variable(reference: .variable(
                        name: .incrementIndex
                    )))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .targetStatesWe0)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .targetStatesReady0)),
                    value: .literal(value: .bit(value: .low))
                )),
            ])
        )
    }

}
