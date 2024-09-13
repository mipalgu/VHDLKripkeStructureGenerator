// WhenCase+ArrangementRunner.swift
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
import VHDLGenerator
import VHDLMachines
import VHDLParsing

extension WhenCase {

    static let arrangementRunnerInitial = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .initial)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .reset)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitToStart)))
            ))
        ])
    )

    static let arrangementRunnerWaitForMachineStart = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .waitForMachineStart)))
        ),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .reset)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForFinish)))
            ))
        ])
    )

    static let arrangementRunnerWaitForFinish = WhenCase(
        condition: .expression(
            expression: .reference(variable: .variable(reference: .variable(name: .waitForFinish)))
        ),
        code: .blocks(blocks: [
            .ifStatement(block: .ifElse(
                condition: .reference(variable: .variable(reference: .variable(name: .finished))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .internalState)),
                    value: .reference(variable: .variable(reference: .variable(name: .setRingletValue)))
                )),
                elseBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .internalState)),
                    value: .reference(variable: .variable(reference: .variable(name: .waitForFinish)))
                ))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .reset)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            ))
        ])
    )

    init?<T>(
        arrangementRunnerSetRingletValueFor arrangement: T,
        machines: [VariableName: any MachineVHDLRepresentable]
    ) where T: ArrangementVHDLRepresentable {
        let mappings = arrangement.arrangement.machines
        let statements: [SynchronousBlock] = mappings.flatMap {
            let name = $0.key.name
            guard let entity = Entity(arrangementRunerFor: arrangement, machines: machines) else {
                fatalError("Failed to create entity.")
            }
            let port = entity.port
            let prefix = "\(name.rawValue)_WRITE_"
            let statements: [SynchronousBlock] = port.signals.compactMap { signal -> SynchronousBlock? in
                let raw = signal.name.rawValue
                guard raw.hasPrefix(prefix) else {
                    return nil
                }
                let suffix = String(raw.dropFirst(prefix.count))
                guard let suffixName = VariableName(rawValue: suffix) else {
                    fatalError("Failed to convert \(suffix).")
                }
                switch suffixName {
                case .state:
                    return SynchronousBlock.statement(statement: .assignment(
                        name: .variable(reference: .variable(name: signal.name)),
                        value: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name.rawValue)NextState")!
                        )))
                    ))
                default:
                    return SynchronousBlock.statement(statement: .assignment(
                        name: .variable(reference: .variable(name: signal.name)),
                        value: .reference(variable: .variable(reference: .member(access: MemberAccess(
                            record: VariableName(rawValue: "\(name.rawValue)WriteSnapshot")!,
                            member: .variable(name: suffixName)
                        ))))
                    ))
                }
            }
            return statements
        }
        let internalStatements: [SynchronousBlock] = [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .reset)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitToStart)))
            ))
        ]
        self.init(
            condition: .expression(
                expression: .reference(variable: .variable(reference: .variable(name: .setRingletValue)))
            ),
            code: .blocks(blocks: internalStatements + statements)
        )
    }

    init?<T>(
        arrangementRunnerWaitToStartFor arrangement: T,
        machines: [VariableName: any MachineVHDLRepresentable]
    ) where T: ArrangementVHDLRepresentable {
        let blocks: [SynchronousBlock] = arrangement.arrangement.machines.compactMap {
            let name = $0.key.name
            let type = $0.key.type
            guard let representation = machines[type] else {
                return nil
            }
            let head = representation.architectureHead
            let currentStateTypes: [Type] = head.statements.compactMap {
                switch $0 {
                case .definition(value: .signal(let signal)):
                    guard signal.name == .currentState else {
                        return nil
                    }
                    return signal.type
                default:
                    return nil
                }
            }
            guard currentStateTypes.count == 1 else {
                return nil
            }
            let stateType = currentStateTypes[0]
            let xorBits = BitVector(values: [BitLiteral](repeating: .high, count: stateType.signalType.bits))
            return SynchronousBlock.ifStatement(block: .ifElse(
                condition: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: "\(name.rawValue)_READ_executeOnEntry")!
                ))),
                ifBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(
                        rawValue: "\(name.rawValue)PreviousRinglet"
                    )!)),
                    value: .logical(operation: .xor(
                        lhs: .reference(variable: .variable(reference: .variable(
                            name: VariableName(rawValue: "\(name.rawValue)_READ_state")!
                        ))),
                        rhs: .literal(value: .vector(value: .bits(value: xorBits)))
                    ))
                )),
                elseBlock: .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: VariableName(
                        rawValue: "\(name.rawValue)PreviousRinglet"
                    )!)),
                    value: .reference(variable: .variable(reference: .variable(
                        name: VariableName(rawValue: "\(name.rawValue)_READ_state")!
                    )))
                ))
            ))
        }
        guard blocks.count == arrangement.arrangement.machines.count else {
            return nil
        }
        let ifBlock: [SynchronousBlock] = [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .reset)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .high))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForMachineStart)))
            ))
        ]
        self.init(
            condition: .expression(
                expression: .reference(variable: .variable(reference: .variable(name: .waitToStart)))
            ),
            code: .ifStatement(block: .ifElse(
                condition: .logical(operation: .and(
                    lhs: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                        rhs: .literal(value: .bit(value: .high))
                    ))),
                    rhs: .reference(variable: .variable(reference: .variable(name: .finished)))
                )),
                ifBlock: .blocks(blocks: ifBlock + blocks),
                elseBlock: .blocks(blocks: [
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .reset)),
                        value: .literal(value: .bit(value: .high))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .busy)),
                        value: .literal(value: .bit(value: .low))
                    )),
                    .statement(statement: .assignment(
                        name: .variable(reference: .variable(name: .internalState)),
                        value: .reference(variable: .variable(reference: .variable(name: .waitToStart)))
                    ))
                ])
            ))
        )
    }

}
