// SynchronousBlock+verifiableMachine.swift
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

extension SynchronousBlock {

    init(internalSignal block: SynchronousBlock, signal: VariableName, newSignal: VariableName) {
        switch block {
        case .blocks(let blocks):
            self = .blocks(blocks: blocks.map {
                SynchronousBlock(internalSignal: $0, signal: signal, newSignal: newSignal)
            })
        case .caseStatement(let caseStatement):
            self = .caseStatement(block: CaseStatement(
                condition: caseStatement.condition,
                cases: caseStatement.cases.map {
                    WhenCase(
                        condition: $0.condition,
                        code: SynchronousBlock(internalSignal: $0.code, signal: signal, newSignal: newSignal)
                    )
                }
            ))
        case .forLoop(let loop):
            self = .forLoop(loop: ForLoop(
                iterator: loop.iterator,
                range: loop.range,
                body: SynchronousBlock(internalSignal: loop.body, signal: signal, newSignal: newSignal)
            ))
        case .ifStatement(let ifBlock):
            switch ifBlock {
            case .ifElse(let condition, let ifBlock, let elseBlock):
                self = .ifStatement(block: .ifElse(
                    condition: condition,
                    ifBlock: SynchronousBlock(internalSignal: ifBlock, signal: signal, newSignal: newSignal),
                    elseBlock: SynchronousBlock(
                        internalSignal: elseBlock, signal: signal, newSignal: newSignal
                    )
                ))
            case .ifStatement(let condition, let ifBlock):
                self = .ifStatement(block: .ifStatement(
                    condition: condition,
                    ifBlock: SynchronousBlock(internalSignal: ifBlock, signal: signal, newSignal: newSignal)
                ))
            }
        case .statement(let statement):
            switch statement {
            case .assignment(let ref, let value):
                guard case .variable(let variable) = ref, variable == signal else {
                    self = .statement(statement: statement)
                    return
                }
                self = .blocks(blocks: [
                    .statement(statement: statement),
                    .statement(statement: .assignment(name: .variable(name: newSignal), value: value))
                ])
            default:
                self = .statement(statement: statement)
            }
        }
    }

    static func internalMutation(for machine: Machine) -> SynchronousBlock? {
        let writeSnapshots = machine.externalSignals.filter { $0.mode != .input }
        let snapshotWrites: [SynchronousBlock] = writeSnapshots.compactMap {
            guard
                let newName = VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)In")
            else {
                return nil
            }
            return SynchronousBlock.statement(statement: .assignment(
                name: .variable(name: $0.name), value: .reference(variable: .variable(name: newName))
            ))
        }
        let snapshotReads: [SynchronousBlock] = writeSnapshots.compactMap {
            guard
                let newName = VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)")
            else {
                return nil
            }
            return SynchronousBlock.statement(statement: .assignment(
                name: .variable(name: newName), value: .reference(variable: .variable(name: $0.name))
            ))
        }
        guard snapshotWrites.count == writeSnapshots.count, snapshotReads.count == writeSnapshots.count else {
            return nil
        }
        return .ifStatement(block: .ifElse(
            condition: .conditional(condition: .comparison(value: .equality(
                lhs: .reference(variable: .variable(name: .setInternalSignals)),
                rhs: .literal(value: .logic(value: .high))
            ))),
            ifBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(name: .currentState),
                    value: .reference(variable: .variable(name: .currentStateIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .previousRinglet),
                    value: .reference(variable: .variable(name: .previousRingletIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .internalState),
                    value: .reference(variable: .variable(name: .internalStateIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .targetState),
                    value: .reference(variable: .variable(name: .targetStateIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .currentStateOut(for: machine)),
                    value: .reference(variable: .variable(name: .currentStateIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .previousRingletOut(for: machine)),
                    value: .reference(variable: .variable(name: .previousRingletIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .internalStateOut(for: machine)),
                    value: .reference(variable: .variable(name: .internalStateIn(for: machine)))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .targetStateOut(for: machine)),
                    value: .reference(variable: .variable(name: .targetStateIn(for: machine)))
                ))
            ] + snapshotWrites),
            elseBlock: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(name: .currentStateOut(for: machine)),
                    value: .reference(variable: .variable(name: .currentState))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .previousRingletOut(for: machine)),
                    value: .reference(variable: .variable(name: .previousRinglet))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .internalStateOut(for: machine)),
                    value: .reference(variable: .variable(name: .internalState))
                )),
                .statement(statement: .assignment(
                    name: .variable(name: .targetStateOut(for: machine)),
                    value: .reference(variable: .variable(name: .targetState))
                ))
            ] + snapshotReads)
        ))
    }

}