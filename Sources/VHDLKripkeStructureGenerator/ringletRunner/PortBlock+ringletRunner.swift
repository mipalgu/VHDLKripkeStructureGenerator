// PortBlock+ringletRunner.swift
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

/// Add inits for creating a ringlet runner port block.
extension PortBlock {

    /// Create the ringlet runner port block for a machine representation.
    /// - Parameter representation: The representation to create the ringlet runner for.
    @inlinable
    init?<T>(ringletRunnerFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let stateSize = VectorSize(supporting: machine.states)
        var machineSignals = machine.machineSignals.map {
            PortSignal(type: $0.type, name: $0.name, mode: .input)
        }
        if machine.transitions.contains(where: { $0.condition.hasAfter }) {
            machineSignals += [PortSignal(type: .natural, name: .ringletCounter, mode: .input)]
        }
        let stateSignals = machine.states.flatMap { (state: State) -> [PortSignal]  in
            state.signals.compactMap { signal in
                guard let newName = VariableName(
                    rawValue: "STATE_\(state.name.rawValue)_\(signal.name.rawValue)"
                ) else {
                    return nil
                }
                return PortSignal(type: signal.type, name: newName, mode: .input)
            }
        }
        guard stateSignals.count == machine.stateVariablesAmount else {
            return nil
        }
        self.init(
            externals: machine.externalSignals,
            machineSignals: machineSignals,
            stateSignals: stateSignals,
            stateSize: stateSize
        )
    }

    /// Create a port block that contains all the signals required for the ringlet runner.
    /// - Parameters:
    ///   - externals: The external signals of a machine.
    ///   - machineSignals: The machine signals inside a machine.
    ///   - stateSignals: The state signals in a machine.
    ///   - stateSize: The size of the state representation for a machine.
    @inlinable
    init?(
        externals: [PortSignal],
        machineSignals: [PortSignal],
        stateSignals: [PortSignal],
        stateSize: VectorSize
    ) {
        guard
            let bits = stateSize.size,
            let defaultState = LogicVector(unsigned: 0, bits: bits)
        else {
            return nil
        }
        let reset = PortSignal(
            type: .stdLogic, name: .reset, mode: .input, defaultValue: .literal(value: .bit(value: .low))
        )
        let stateSignal = PortSignal(
            type: .ranged(type: .stdLogicVector(size: stateSize)),
            name: .state,
            mode: .input,
            defaultValue: .literal(value: .vector(value: .logics(value: defaultState))),
            comment: nil
        )
        let previousRinglet = PortSignal(
            type: .ranged(type: .stdLogicVector(size: stateSize)),
            name: .previousRinglet,
            mode: .input,
            defaultValue: .literal(value: .vector(value: .logics(
                value: LogicVector(values: [LogicLiteral](repeating: .highImpedance, count: bits))
            )))
        )
        let readSnapshot = PortSignal(
            type: .alias(name: .readSnapshotType), name: .readSnapshotState, mode: .output
        )
        let writeSnapshot = PortSignal(
            type: .alias(name: .writeSnapshotType), name: .writeSnapshotState, mode: .output
        )
        let nextState = PortSignal(
            type: .ranged(type: .stdLogicVector(size: stateSize)), name: .nextState, mode: .output
        )
        let finished = PortSignal(
            type: .boolean,
            name: .finished,
            mode: .output,
            defaultValue: .literal(value: .boolean(value: true))
        )
        self.init(
            signals: [.clk, reset, stateSignal] + externals + machineSignals + stateSignals +
                [previousRinglet, readSnapshot, writeSnapshot, nextState, finished]
        )
    }

}
