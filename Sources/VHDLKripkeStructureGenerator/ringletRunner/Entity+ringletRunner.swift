// Entity+ringletRunner.swift
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

/// Add ringlet runner declaration.
extension Entity {

    // swiftlint:disable function_body_length

    /// Create the entity declaration for the ringlet runner.
    /// - Parameter representation: The machine to create the ringlet runner for.
    @inlinable
    init?<T>(ringletRunnerFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard let name = VariableName(rawValue: "\(machine.name.rawValue)RingletRunner") else {
            return nil
        }
        guard machine.drivingClock >= 0, machine.drivingClock < machine.clocks.count else {
            return nil
        }
        let clk = machine.clocks[machine.drivingClock]
        guard
            let stateType = representation.stateType, let numberOfBits = representation.numberOfStateBits
        else {
            return nil
        }
        let externals = machine.externalSignals.map {
            let defaultValue = $0.mode != .input ? nil : $0.defaultValue
            return PortSignal(
                type: $0.type,
                name: $0.name,
                mode: .input,
                defaultValue: defaultValue
            )
        }
        var machineSignals = machine.machineSignals.map {
            // swiftlint:disable:next force_unwrapping
            PortSignal(signal: $0, in: machine, mode: .input)!
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineSignals += [PortSignal(type: .natural, name: .ringletCounter, mode: .input)]
        }
        let stateSignals = machine.stateVariables.flatMap { state, variables in
            let preamble = "\(machine.name.rawValue)_STATE_\(state.rawValue)_"
            return variables.map {
                PortSignal(
                    type: $0.type,
                    // swiftlint:disable:next force_unwrapping
                    name: VariableName(pre: preamble, name: $0.name)!,
                    mode: .input,
                    defaultValue: $0.defaultValue
                )
            }
        }
        let clockSignal = PortSignal(clock: clk)
        let allSignals = [
            clockSignal,
            PortSignal(
                type: .stdLogic, name: .reset, mode: .input, defaultValue: .literal(value: .bit(value: .low))
            ),
            PortSignal(
                type: stateType,
                name: .state,
                mode: .input,
                defaultValue: .literal(value: .vector(value: .bits(value: BitVector(
                    values: [BitLiteral](repeating: .low, count: numberOfBits)
                ))))
            )
        ] + externals + machineSignals + stateSignals + [
            PortSignal(
                type: stateType,
                name: .previousRinglet,
                mode: .input,
                defaultValue: .literal(value: .vector(value: .logics(value: LogicVector(
                    values: [LogicLiteral](repeating: .highImpedance, count: numberOfBits)
                ))))
            ),
            PortSignal(type: .alias(name: .readSnapshotType), name: .readSnapshotState, mode: .output),
            PortSignal(type: .alias(name: .writeSnapshotType), name: .writeSnapshotState, mode: .output),
            PortSignal(type: stateType, name: .nextState, mode: .output),
            PortSignal(
                type: .boolean,
                name: .finished,
                mode: .output,
                defaultValue: .literal(value: .boolean(value: true))
            )
        ]
        guard let block = PortBlock(signals: allSignals) else {
            return nil
        }
        self.init(name: name, port: block)
    }

    // swiftlint:enable function_body_length

}

/// Add state type property.
extension MachineVHDLRepresentable {

    /// Get type of state array.
    @inlinable var stateType: SignalType? {
        let currentStateSignal: LocalSignal? = self.architectureHead.statements.lazy
            .compactMap { (statement: HeadStatement) -> LocalSignal? in
                guard
                    case .definition(let def) = statement,
                    case .signal(let signal) = def
                else {
                    return nil
                }
                return signal
            }
            .first { $0.name == .currentState }
        guard case .signal(let type) = currentStateSignal?.type else {
            return nil
        }
        return type
    }

    /// The number of bits in the state encoding.
    @inlinable var numberOfStateBits: Int? {
        self.architectureHead.statements.lazy.compactMap {
            guard
                case .definition(let def) = $0,
                case .signal(let signal) = def,
                signal.name == .currentState,
                case .signal(let type) = signal.type,
                case .ranged(let vec) = type
            else {
                return nil
            }
            return vec.size.size
        }
        .first
    }

}
