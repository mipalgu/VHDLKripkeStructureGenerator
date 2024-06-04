// ComponentInstantiation+machineRunnerInvocation.swift
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

/// Add invocation for machine runner.
extension ComponentInstantiation {

    // swiftlint:disable function_body_length

    /// Create a component invocation for the machine runner. This invocation assumes that signals will be
    /// mapped into a record type.
    /// - Parameters:
    ///   - representation: The machine to create the invocation for.
    ///   - name: The name of the record type to map the signals into.
    ///   - label: The label of the invocation.
    @inlinable
    init?<T>(
        machineRunnerInvocationFor representation: T, record name: VariableName, label: VariableName
    ) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard let runnerName = VariableName(name: representation.entity.name, post: "MachineRunner") else {
            return nil
        }
        let externals = machine.externalSignals.map(\.name)
        let snapshots: [[VariableName]] = machine.externalSignals.compactMap {
            guard let snapshot = VariableName(pre: "\(representation.entity.name.rawValue)_", name: $0.name) else {
                return nil
            }
            guard $0.mode != .input else {
                return [snapshot]
            }
            guard
                let inputSnapshot = VariableName(pre: "\(representation.entity.name.rawValue)_", name: $0.name, post: "In")
            else {
                return nil
            }
            return [snapshot, inputSnapshot]
        }
        guard externals.count == snapshots.count else {
            return nil
        }
        let unwrappedSnapshots = snapshots.flatMap { $0 }
        var machineVariables: [[VariableName]] = machine.machineSignals.compactMap {
            guard
                let output = VariableName(pre: "\(representation.entity.name.rawValue)_", name: $0.name),
                let input = VariableName(pre: "\(representation.entity.name.rawValue)_", name: $0.name, post: "In")
            else {
                return nil
            }
            return [output, input]
        }
        guard machineVariables.count == machine.machineSignals.count else {
            return nil
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineVariables += [
                [
                    VariableName(pre: "\(representation.entity.name.rawValue)_", name: .ringletCounter)!,
                    VariableName(pre: "\(representation.entity.name.rawValue)_", name: .ringletCounter, post: "In")!
                ]
            ]
        }
        let machineVariablesUnwrapped = machineVariables.flatMap { $0 }
        let stateVariables: [VariableName] = machine.stateVariables.flatMap { stateName, variables in
            let preamble = "\(representation.entity.name.rawValue)_STATE_\(stateName.rawValue)_"
            return variables.compactMap { (variable: LocalSignal) -> [VariableName]? in
                guard
                    let input = VariableName(pre: preamble, name: variable.name),
                    let output = VariableName(pre: preamble, name: variable.name, post: "In")
                else {
                    return nil
                }
                return [input, output]
            }
        }
        .flatMap { $0 }
        guard stateVariables.count == machine.stateVariablesAmount * 2 else {
            return nil
        }
        let allVariables = externals + unwrappedSnapshots + machineVariablesUnwrapped + stateVariables
            + [.reset, .goalInternalState, .finished]
        let recordMapping = allVariables.map {
            VariableMap(
                lhs: .variable(reference: .variable(name: $0)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: $0))
                ))))
            )
        }
        let map = PortMap(variables: [VariableMap](machineRunnerControlRecordMapped: name) + recordMapping)
        self.init(label: label, name: runnerName, port: map)
    }

}

/// Add control signals for machine runner.
extension Array where Element == VariableMap {

    /// Create the control signals for the machine runner. This assumes that the signals will be mapped into a
    /// record type.
    /// - Parameter name: The name of the record type to map the signals into.
    @inlinable
    init(machineRunnerControlRecordMapped name: VariableName) {
        self.init([
            VariableMap(
                lhs: .variable(reference: .variable(name: .clk)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: .clk))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .internalStateIn)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .internalStateIn))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .internalStateOut)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .internalStateOut))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .currentStateIn)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .currentStateIn))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .currentStateOut)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .currentStateOut))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .previousRingletIn)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .previousRingletIn))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .previousRingletOut)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .previousRingletOut))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .targetStateIn)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .targetStateIn))
                ))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .targetStateOut)),
                rhs: .expression(value: .reference(variable: .variable(reference: .member(
                    access: MemberAccess(record: name, member: .variable(name: .targetStateOut))
                ))))
            )
        ])
    }

    // swiftlint:enable function_body_length

}
