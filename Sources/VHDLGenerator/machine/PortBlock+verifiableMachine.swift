// Port+verifiableMachine.swift
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

/// Add inits to `PortBlock` for new verifiable format.
extension PortBlock {

    // swiftlint:disable function_body_length

    /// Create a new `PortBlock` for the verifiable machine format from the given `MachineRepresentation`.
    /// - Parameter representation: The representation to convert to a verifiable machine, i.e. a format that
    /// exposes internal signals for verification.
    /// - Warning: A machine that uses type aliases will make this initialiser return nil.
    @inlinable
    init?<T>(verifiable representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard
            let currentStateIn = PortSignal(currentStateInFor: representation),
            let currentStateOut = PortSignal(currentStateOutFor: representation),
            let previousRingletIn = PortSignal(previousRingletInFor: representation),
            let previousRingletOut = PortSignal(previousRingletOutFor: representation),
            let internalStateIn = PortSignal(internalStateInFor: representation),
            let internalStateOut = PortSignal(internalStateOutFor: representation),
            let targetStateIn = PortSignal(targetStateInFor: representation),
            let targetStateOut = PortSignal(targetStateOutFor: representation)
        else {
            return nil
        }
        let externals = machine.externalSignals
        let snapshots: [PortSignal] = externals.flatMap { (signal: PortSignal) -> [PortSignal] in
            var ports: [PortSignal] = []
            switch signal.mode {
            case .output, .inputoutput, .buffer:
                // swiftlint:disable:next force_unwrapping
                let newName = VariableName(
                    rawValue: "\(representation.entity.name.rawValue)_\(signal.name.rawValue)In"
                )!
                ports += [PortSignal(type: signal.type, name: newName, mode: .input)]
            default:
                break
            }
            // swiftlint:disable:next force_unwrapping
            let newName = VariableName(
                rawValue: "\(representation.entity.name.rawValue)_\(signal.name.rawValue)"
            )!
            return [PortSignal(type: signal.type, name: newName, mode: .output)] + ports
        }
        let machineSignals = machine.machineSignals
        var machinePorts = machineSignals.compactMap {
            PortSignal(signal: $0, in: representation, mode: .output)
        }
        var machineInputs: [PortSignal] = machineSignals.compactMap { (signal: LocalSignal) -> PortSignal? in
            guard
                let name = VariableName(
                    rawValue: "\(representation.entity.name.rawValue)_\(signal.name.rawValue)In"
                ),
                case .signal(let type) = signal.type
            else {
                return nil
            }
            return PortSignal(type: type, name: name, mode: .input)
        }
        let stateSignals = machine.states.map {
            ($0.name, $0.signals)
        }
        let stateCount = stateSignals.reduce(0) { $0 + $1.1.count }
        let stateSignalsIn = stateSignals.flatMap { state, signals in
            signals.compactMap { (signal: LocalSignal) -> PortSignal? in
                guard
                    let newName = VariableName(
                        rawValue: "\(representation.entity.name.rawValue)_STATE_" +
                            "\(state.rawValue)_\(signal.name.rawValue)In"
                    ),
                    case .signal(let type) = signal.type
                else {
                    return nil
                }
                return PortSignal(type: type, name: newName, mode: .input)
            }
        }
        let stateSignalsOut = stateSignals.flatMap { state, signals in
            signals.compactMap { (signal: LocalSignal) -> PortSignal? in
                guard
                    let newName = VariableName(
                        rawValue: "\(representation.entity.name.rawValue)_STATE_" +
                            "\(state.rawValue)_\(signal.name.rawValue)"
                    ),
                    case .signal(let type) = signal.type
                else {
                    return nil
                }
                return PortSignal(type: type, name: newName, mode: .output)
            }
        }
        guard
            machinePorts.count == machineSignals.count,
            machineInputs.count == machineSignals.count,
            stateSignalsIn.count == stateCount,
            stateSignalsOut.count == stateCount
        else {
            return nil
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machinePorts += [
                PortSignal(
                    type: .natural,
                    name: VariableName(
                        rawValue: "\(representation.entity.name.rawValue)_" +
                            "\(VariableName.ringletCounter.rawValue)"
                    )!,
                    mode: .output
                )
            ]
            machineInputs += [
                PortSignal(
                    type: .natural,
                    name: VariableName(
                        rawValue: "\(representation.entity.name.rawValue)_" +
                            "\(VariableName.ringletCounter.rawValue)In"
                    )!,
                    mode: .input
                )
            ]
        }
        let originalSignals = representation.entity.port.signals
        self.init(
            signals: originalSignals + snapshots + machinePorts + machineInputs + stateSignalsOut +
                stateSignalsIn +
            [
                currentStateIn,
                previousRingletIn,
                internalStateIn,
                targetStateIn,
                currentStateOut,
                previousRingletOut,
                internalStateOut,
                targetStateOut,
                PortSignal.setInternalSignals,
                PortSignal.reset
            ]
        )
    }

    // swiftlint:enable function_body_length

}
