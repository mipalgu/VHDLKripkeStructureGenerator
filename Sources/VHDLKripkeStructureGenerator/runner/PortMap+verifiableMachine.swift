// PortMap+verifiableMachine.swift
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

/// Add initialiser for machine runner from representation.
extension PortMap {

    /// Initialises the port map with the variables for the machine instantiation in the runner. This mapping
    /// uses the internal signals of the machine runner in the invocation.
    /// - Parameter representation: The representation to instantitate in the runner.
    @inlinable
    init?<T>(runnerMachineInst representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let machineName = machine.name
        var machineVariables: [VariableMap] = representation.machine.machineSignals.compactMap {
            [VariableMap](machineName: machineName, variable: $0.name)
        }
        .flatMap { $0 }
        guard machineVariables.count == representation.machine.machineSignals.count * 2 else {
            return nil
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            guard let counter = [VariableMap](machineName: machineName, variable: .ringletCounter) else {
                return nil
            }
            machineVariables += counter
        }
        let stateVariables: [VariableMap] = representation.machine.states.flatMap { state in
            let variables = state.signals.map(\.name)
            let mappings: [VariableMap] = variables.compactMap {
                [VariableMap](state: state, machineName: machineName, variable: $0)
            }
            .flatMap { $0 }
            return mappings
        }
        guard stateVariables.count == representation.machine.stateVariablesAmount * 2 else {
            return nil
        }
        let externals = representation.machine.externalSignals.map {
            VariableMap(
                lhs: .variable(reference: .variable(name: .name(for: $0))),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: $0.name))))
            )
        }
        let snapshots: [VariableMap] = representation.machine.externalSignals.compactMap {
            [VariableMap](machineName: machineName, snapshot: $0)
        }
        .flatMap { $0 }
        let outputExternals = representation.machine.externalSignals.filter { $0.mode != .input }
        guard snapshots.count == (externals.count + outputExternals.count) else {
            return nil
        }
        let clkMap = VariableMap(
            lhs: .variable(reference: .variable(name: .clk)),
            rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: .clk))))
        )
        let constants = [VariableMap](runner: representation)
        self.init(variables: [clkMap] + externals + snapshots + machineVariables + stateVariables + constants)
    }

}

/// Add initialiser for runner.
extension Array where Element == VariableMap {

    /// Initialises the array with the variables for the machine instantiation in the runner.
    /// - Parameter representation: The machine to instantiate.
    @inlinable
    init<T>(runner representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        self = [
            VariableMap(
                lhs: .variable(reference: .variable(name: .currentStateIn(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .currentStateIn)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .previousRingletIn(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .previousRingletIn)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .internalStateIn(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .internalStateIn)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .targetStateIn(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .targetStateIn)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .currentStateOut(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .currentStateOut)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .previousRingletOut(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .previousRingletOut)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .internalStateOut(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .internalState)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .targetStateOut(for: machine))),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .targetStateOut)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .setInternalSignals)),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .setInternalSignals)))
                )
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: .reset)),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: .rst)))
                )
            )
        ]
    }

}

extension VariableName {

    @inlinable
    init?(machineName: VariableName, stateName: VariableName, variable: VariableName, post: String = "") {
        let pre = "\(machineName.rawValue)_STATE_\(stateName.rawValue)_"
        self.init(rawValue: "\(pre)\(variable.rawValue)\(post)")
    }

    @inlinable
    init?(machineName: VariableName, variable: VariableName, post: String = "") {
        let pre = "\(machineName.rawValue)_"
        self.init(rawValue: "\(pre)\(variable.rawValue)\(post)")
    }

}

extension Array where Element == VariableMap {

    @inlinable
    init?(state: State, machineName: VariableName, variable: VariableName) {
        guard
            let name = VariableName(machineName: machineName, stateName: state.name, variable: variable),
            let inputName = VariableName(
                machineName: machineName, stateName: state.name, variable: variable, post: "In"
            )
        else {
            return nil
        }
        self.init(name: name, inputName: inputName)
    }

    @inlinable
    init?(machineName: VariableName, variable: VariableName) {
        guard
            let name = VariableName(machineName: machineName, variable: variable),
            let inputName = VariableName(
                machineName: machineName, variable: variable, post: "In"
            )
        else {
            return nil
        }
        self.init(name: name, inputName: inputName)
    }

    @inlinable
    init?(machineName: VariableName, snapshot signal: PortSignal) {
        guard signal.mode == .input else {
            self.init(machineName: machineName, variable: signal.name)
            return
        }
        guard let name = VariableName(machineName: machineName, variable: signal.name) else {
            return nil
        }
        self = [
            VariableMap(
                lhs: .variable(reference: .variable(name: name)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: name))))
            )
        ]
    }

    @inlinable
    init(name: VariableName, inputName: VariableName) {
        self = [
            VariableMap(
                lhs: .variable(reference: .variable(name: name)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: name))))
            ),
            VariableMap(
                lhs: .variable(reference: .variable(name: inputName)),
                rhs: .expression(
                    value: .reference(variable: .variable(reference: .variable(name: inputName)))
                )
            )
        ]
    }

}
