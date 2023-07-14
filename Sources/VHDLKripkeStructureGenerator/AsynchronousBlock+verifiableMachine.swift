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

/// Add verifiable initialisers.
extension AsynchronousBlock {

    /// Detect whether this block contains a ``ProcessBlock``.
    @inlinable var hasProcess: Bool {
        switch self {
        case .blocks(let blocks):
            return blocks.lazy.map(\.hasProcess).contains(true)
        case .process:
            return true
        default:
            return false
        }
    }

    /// Converts a machine representation body into a new format for verification. This init exposes internal
    /// signals so that they may be included in a Kripke structure.
    /// - Parameter representation: The representation of the machine to convert.
    @inlinable
    init?<T>(verifiable representation: T) where T: MachineVHDLRepresentable {
        let body = representation.architectureBody
        guard body.hasProcess else {
            return nil
        }
        let machine = representation.machine
        let readableVariables = machine.externalSignals.filter { $0.mode == .input }
        let snapshots: [(VariableName, VariableName)] = readableVariables.compactMap {
            guard let name = VariableName(rawValue: "\(machine.name.rawValue)_\($0.name.rawValue)") else {
                return nil
            }
            return ($0.name, name)
        }
        guard snapshots.count == readableVariables.count else {
            return nil
        }
        let assignments = snapshots.map {
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
            guard let newProcess = ProcessBlock(verifiable: process, in: machine) else {
                return nil
            }
            self = .blocks(blocks: assignments + [.process(block: newProcess)])
        case .component, .statement:
            return nil
        }
    }

    /// Convers all process blocks within `block` into their verifiable versions. If any process block cannot
    /// be converted, this initializer will return `nil`.
    /// - Parameters:
    ///   - block: The block to convert.
    ///   - machine: The machine this block represents.
    @inlinable
    init?(verifiable block: AsynchronousBlock, in machine: Machine) {
        switch block {
        case .blocks(let blocks):
            let newBlocks = blocks.compactMap { AsynchronousBlock(verifiable: $0, in: machine) }
            guard newBlocks.count == blocks.count else {
                return nil
            }
            self = .blocks(blocks: newBlocks)
        case .process(let process):
            guard let newProcess = ProcessBlock(verifiable: process, in: machine) else {
                return nil
            }
            self = .process(block: newProcess)
        default:
            self = block
        }
    }

}
