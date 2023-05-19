// ArchitectureBody+verifiableMachine.swift
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

    var hasProcess: Bool {
        switch self {
        case .blocks(let blocks):
            return blocks.map(\.hasProcess).contains(true)
        case .process:
            return true
        default:
            return false
        }
    }

    init?(verifiable representation: MachineRepresentation) {
        let body = representation.architectureBody
        guard body.hasProcess else {
            return nil
        }
        let machine = representation.machine
        let stateVariables = machine.states.flatMap { $0.signals }
        let localVariables = stateVariables + machine.machineSignals
        let machineVariables: [(VariableName, VariableName)] = localVariables.compactMap {
            guard let name = VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)") else {
                return nil
            }
            return ($0.name, name)
        }
        let readableVariables = machine.externalSignals.filter { $0.mode == .input }
        let snapshots: [(VariableName, VariableName)] = readableVariables.compactMap {
            guard let name = VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)") else {
                return nil
            }
            return ($0.name, name)
        }
        guard
            machineVariables.count == localVariables.count,
            snapshots.count == readableVariables.count
        else {
            return nil
        }
        let assignments = (machineVariables + snapshots).map {
            AsynchronousBlock.statement(statement: .assignment(
                name: .variable(name: $0.1), value: .reference(variable: .variable(name: $0.0))
            ))
        }
        switch body {
        case .blocks(let blocks):
            let newBlocks = blocks.compactMap { AsynchronousBlock(verifiable: $0, in: machine) }
            guard newBlocks.count == blocks.count else {
                return nil
            }
            self = .blocks(blocks: assignments + newBlocks)
        case .process(let process):
            guard let newProcess = AsynchronousBlock(verifiable: process, in: machine) else {
                return nil
            }
            self = .blocks(blocks: assignments + [newProcess])
        case .component, .statement:
            return nil
        }
    }

    init?(verifiable block: AsynchronousBlock, in machine: Machine) {
        switch block {
        case .blocks(let blocks):
            let newBlocks = blocks.compactMap { AsynchronousBlock(verifiable: $0, in: machine) }
            guard newBlocks.count == blocks.count else {
                return nil
            }
            self = .blocks(blocks: newBlocks)
        case .process(let process):
            guard let newBlock = AsynchronousBlock(verifiable: process, in: machine) else {
                return nil
            }
            self = newBlock
        default:
            self = block
        }
    }

    init?(verifiable process: ProcessBlock, in machine: Machine) {
        let drivingClock = machine.clocks[machine.drivingClock].name
        guard
            process.sensitivityList == [drivingClock],
            case .ifStatement(let block) = process.code,
            case .ifStatement(let condition, let secondBlock) = block,
            case .conditional(let ifCondition) = condition,
            case .edge(let edge) = ifCondition,
            case .rising(let clockExp) = edge,
            case .reference(let ref) = clockExp,
            case .variable(let clock) = ref,
            drivingClock == clock,
            case .caseStatement(let caseStatement) = secondBlock,
            case .reference(let caseRef) = caseStatement.condition,
            case .variable(let caseVar) = caseRef,
            caseVar == .internalState
        else {
            return nil
        }
        let newBlock = SynchronousBlock(
            internalSignal: SynchronousBlock(
                internalSignal: SynchronousBlock(
                    internalSignal: SynchronousBlock(
                        internalSignal: secondBlock,
                        signal: .internalState,
                        newSignal: .internalStateOut(for: machine)
                    ),
                    signal: .currentState,
                    newSignal: VariableName.currentStateOut(for: machine)
                ),
                signal: .previousRinglet,
                newSignal: .previousRingletOut(for: machine)
            ),
            signal: .targetState,
            newSignal: .targetStateOut(for: machine)
        )
        let writeExternals = machine.externalSignals.filter { $0.mode != .input }
        let actuatorSnapshots: [SynchronousBlock] = writeExternals.compactMap {
            guard let newName = VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)") else {
                return nil
            }
            return SynchronousBlock.statement(statement: .assignment(
                name: .variable(name: newName),
                value: .reference(variable: .variable(name: $0.name))
            ))
        }
        guard
            actuatorSnapshots.count == writeExternals.count,
            let elseBlock = SynchronousBlock.internalMutation(for: machine)
        else {
            return nil
        }
        let resetStatement = SynchronousBlock.ifStatement(block: .ifElse(
            condition: .conditional(condition: .comparison(value: .equality(
                lhs: .reference(variable: .variable(name: .reset)), rhs: .literal(value: .logic(value: .high))
            ))),
            ifBlock: .blocks(blocks: actuatorSnapshots + [newBlock]),
            elseBlock: elseBlock
        ))
        self = .process(block: ProcessBlock(
            sensitivityList: process.sensitivityList,
            code: .ifStatement(block: .ifStatement(condition: condition, ifBlock: resetStatement))
        ))
    }

}