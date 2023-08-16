// PortBlock+runner.swift
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

import Foundation
import VHDLMachines
import VHDLParsing

/// Add initialiser for the runner.
extension PortBlock {

    /// Create the port block for the machine runner that enacts the given machine representation.
    /// - Parameter representation: The representation of the machine that is controlled by this machine
    /// runner.
    @inlinable
    init?<T>(runnerFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let label = "\(machine.name.rawValue)_"
        let snapshots: [PortSignal] = machine.externalSignals
            .compactMap { (signal: PortSignal) -> [PortSignal]? in
                guard
                    let name = VariableName(pre: label, name: signal.name),
                    let inName = VariableName(name: name, post: "In")
                else {
                    return nil
                }
                let signals = [PortSignal(type: signal.type, name: name, mode: .output)]
                if signal.mode == .output {
                    return signals + [PortSignal(type: signal.type, name: inName, mode: .input)]
                } else {
                    return signals
                }
            }
            .flatMap { $0 }
        let expectedSnapshotCount = machine.externalSignals.count + machine.externalSignals.filter {
            $0.mode == .output
        }.count
        guard snapshots.count == expectedSnapshotCount else {
            return nil
        }
        let machineVariables: [PortSignal] = machine.machineSignals
            .compactMap { (signal: LocalSignal) -> [PortSignal]? in
                guard
                    let name = VariableName(pre: label, name: signal.name),
                    let inName = VariableName(name: name, post: "In"),
                    case .signal(let type) = signal.type
                else {
                    return nil
                }
                return [
                    PortSignal(type: type, name: name, mode: .output),
                    PortSignal(type: type, name: inName, mode: .input)
                ]
            }
            .flatMap { $0 }
        guard machineVariables.count == machine.machineSignals.count * 2 else {
            return nil
        }
        let stateSignals: [PortSignal] = machine.states.flatMap { (state: State) -> [PortSignal] in
            state.signals.compactMap { (signal: LocalSignal) -> [PortSignal]? in
                guard
                    let name = VariableName(pre: "\(label)STATE_\(state.name.rawValue)_", name: signal.name),
                    let inName = VariableName(name: name, post: "In"),
                    case .signal(let type) = signal.type
                else {
                    return nil
                }
                return [
                    PortSignal(type: type, name: name, mode: .output),
                    PortSignal(type: type, name: inName, mode: .input)
                ]
            }
            .flatMap { $0 }
        }
        guard stateSignals.count == machine.stateVariablesAmount * 2 else {
            return nil
        }
        self.init(
            numberOfStates: machine.states.count,
            externals: machine.externalSignals,
            snapshots: snapshots,
            machineVariables: machineVariables,
            stateSignals: stateSignals
        )
    }

    /// Initialise a `PortBlock` with the given converted representations for the machine's variables. This
    /// initialiser assumes the port definitions are already correct and verified for a given machine.
    /// - Parameters:
    ///   - numberOfStates: The number of states in the machine.
    ///   - externals: The external signals in the machine.
    ///   - snapshots: The snapshot definitions for the machine.
    ///   - machineVariables: The machine variables in the machine.
    ///   - stateSignals: The state variables in the machine.
    @inlinable
    init?(
        numberOfStates: Int,
        externals: [PortSignal],
        snapshots: [PortSignal],
        machineVariables: [PortSignal],
        stateSignals: [PortSignal]
    ) {
        guard
            numberOfStates > 0,
            let bitsRequired = BitLiteral.bitsRequired(for: numberOfStates - 1),
            bitsRequired > 0
        else {
            return nil
        }
        let currentStateBits = SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: bitsRequired - 1)),
            lower: .literal(value: .integer(value: 0))
        )))
        let internalStateSize = SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: 2)), lower: .literal(value: .integer(value: 0))
        )))
        let trackers: [PortSignal] = [
            PortSignal(type: .stdLogic, name: .clk, mode: .input),
            PortSignal(type: internalStateSize, name: .internalStateIn, mode: .input),
            PortSignal(type: internalStateSize, name: .internalStateOut, mode: .output),
            PortSignal(type: currentStateBits, name: .currentStateIn, mode: .input),
            PortSignal(type: currentStateBits, name: .currentStateOut, mode: .output),
            PortSignal(type: currentStateBits, name: .previousRingletIn, mode: .input),
            PortSignal(type: currentStateBits, name: .previousRingletOut, mode: .output),
            PortSignal(type: currentStateBits, name: .targetStateIn, mode: .input),
            PortSignal(type: currentStateBits, name: .targetStateOut, mode: .output)
        ]
        let controlSignals: [PortSignal] = [
            PortSignal(type: .stdLogic, name: .reset, mode: .input),
            PortSignal(type: internalStateSize, name: .goalInternalState, mode: .input),
            PortSignal(
                type: .boolean,
                name: .finished,
                mode: .output,
                defaultValue: .literal(value: .boolean(value: true))
            )
        ]
        self.init(
            signals: trackers + externals + snapshots + machineVariables + stateSignals + controlSignals
        )
    }

}

/// Add label init to string.
extension String {

    /// Create a label for a `VariableName` that contains lowercase versions of all uppercase letters. For
    /// example, the name `HelloWorld` would be shortened to `hw`.
    /// - Parameter name: The name to convert into a label.
    @inlinable
    init(labelFor name: VariableName) {
        let prepending = String(
            name.rawValue.lazy
                .compactMap { $0.unicodeScalars.first }
                .filter { CharacterSet.uppercaseLetters.contains($0) }
                .map { Character($0) }
        )
        if prepending.isEmpty {
            self = name.rawValue
        } else {
            self = prepending.lowercased()
        }
    }

}
