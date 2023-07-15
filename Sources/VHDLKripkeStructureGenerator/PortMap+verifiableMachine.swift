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

import VHDLMachines
import VHDLParsing

/// Add initialiser for machine runner from representation.
extension PortMap {

    /// Initialises the port map with the variables for the machine instantiation in the runner. This mapping
    /// uses the internal signals of the machine runner in the invocation.
    /// - Parameter representation: The representation to instantitate in the runner.
    @inlinable
    init?<T>(runnerMachineInst representation: T) where T: MachineVHDLRepresentable {
        let machineVariables: [VariableMap] = representation.machine.machineSignals.compactMap {
            guard let name = VariableName(
                pre: "\(representation.machine.name.rawValue)_", name: $0.name
            ) else {
                return nil
            }
            return VariableMap(
                lhs: .variable(name: name), rhs: .reference(variable: .variable(name: $0.name))
            )
        }
        guard machineVariables.count == representation.machine.machineSignals.count else {
            return nil
        }
        let stateVariables: [VariableMap] = representation.machine.states.flatMap { state in
            state.signals.compactMap { variable in
                guard let name = VariableName(
                    pre: "\(representation.machine.name.rawValue)_STATE_\(state.name.rawValue)_",
                    name: variable.name
                ) else {
                    return nil
                }
                return VariableMap(
                    lhs: .variable(name: name), rhs: .reference(variable: .variable(name: variable.name))
                )
            }
        }
        guard stateVariables.count == representation.machine.stateVariablesAmount else {
            return nil
        }
        let externals = representation.machine.externalSignals.map {
            VariableMap(
                lhs: .variable(name: .name(for: $0)), rhs: .reference(variable: .variable(name: $0.name))
            )
        }
        let snapshots: [VariableMap] = representation.machine.externalSignals.compactMap {
            guard let name = VariableName(
                pre: "\(representation.machine.name.rawValue)_", name: $0.name
            ) else {
                return nil
            }
            return VariableMap(
                lhs: .variable(name: name), rhs: .reference(variable: .variable(name: $0.name))
            )
        }
        guard snapshots.count == externals.count else {
            return nil
        }
        let clkMap = VariableMap(lhs: .variable(name: .clk), rhs: .reference(variable: .variable(name: .clk)))
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
                lhs: .variable(name: .currentStateIn(for: machine)),
                rhs: .reference(variable: .variable(name: .currentStateIn))
            ),
            VariableMap(
                lhs: .variable(name: .previousRingletIn(for: machine)),
                rhs: .reference(variable: .variable(name: .previousRingletIn))
            ),
            VariableMap(
                lhs: .variable(name: .internalStateIn(for: machine)),
                rhs: .reference(variable: .variable(name: .internalStateIn))
            ),
            VariableMap(
                lhs: .variable(name: .currentStateOut(for: machine)),
                rhs: .reference(variable: .variable(name: .currentStateOut))
            ),
            VariableMap(
                lhs: .variable(name: .targetStateIn(for: machine)),
                rhs: .reference(variable: .variable(name: .targetStateIn))
            ),
            VariableMap(
                lhs: .variable(name: .targetStateOut(for: machine)),
                rhs: .reference(variable: .variable(name: .targetStateOut))
            ),
            VariableMap(
                lhs: .variable(name: .previousRingletOut(for: machine)),
                rhs: .reference(variable: .variable(name: .previousRingletOut))
            ),
            VariableMap(
                lhs: .variable(name: .internalStateOut(for: machine)),
                rhs: .reference(variable: .variable(name: .internalState))
            ),
            VariableMap(
                lhs: .variable(name: .setInternalSignals),
                rhs: .reference(variable: .variable(name: .setInternalSignals))
            ),
            VariableMap(lhs: .variable(name: .reset), rhs: .reference(variable: .variable(name: .rst)))
        ]
    }

}
