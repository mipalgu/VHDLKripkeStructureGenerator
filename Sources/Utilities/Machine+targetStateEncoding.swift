// Machine+targetStateEncoding.swift
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

public extension Machine {

    /// The number of values represented by the pending state encoding.
    @inlinable var numberOfPendingStates: Int {
        self.numberOfTargetStates * 2
    }

    /// The number of values represented by the target state encoding.
    @inlinable var numberOfTargetStates: Int {
        let numberOfValues = self.externalSignals.filter { $0.mode != .input }
            .map { $0.type.signalType.numberOfValues } +
            self.machineSignals.map { $0.type.signalType.numberOfValues } +
            self.stateVariables.values.flatMap {
                $0.map { $0.type.signalType.numberOfValues }
            }
        return numberOfValues.reduce(self.reachableStates.count * 2, *)
    }

    /// The type of a single encoded pending state.
    @inlinable var pendingStateEncoding: SignalType {
        .ranged(type: .stdLogicVector(size: pendingStateSize))
    }

    /// The size of a single encoded pending state.
    @inlinable var pendingStateSize: VectorSize {
        .downto(
            upper: .literal(value: .integer(value: max(0, targetStateBits - 1))),
            lower: .literal(value: .integer(value: 0))
        )
    }

    /// Find all reachable states in this machine.
    @inlinable var reachableStates: [State] {
        let reachableStates: [Int]
        if let suspendedState = self.suspendedState {
            reachableStates = [self.initialState, suspendedState]
        } else {
            reachableStates = [self.initialState]
        }
        let allReachableStates = self.states.indices.filter { index in
            let targetTransitions = self.transitions.filter { $0.target == index }
            return reachableStates.contains { reachableIndex in
                targetTransitions.contains { transition in
                    self.isTransitionReachable(from: reachableIndex, transition: transition)
                }
            }
        }
        let reachableSet = Set(allReachableStates + reachableStates)
        return reachableSet.map { self.states[$0] }
    }

    /// The number of bits in a target state encoding.
    @inlinable var targetStateBits: Int {
        let bits: [Int] = self.externalSignals.filter { $0.mode != .input }
            .map { $0.type.signalType.bits } +
            self.machineSignals.map { $0.type.signalType.bits } +
            self.stateVariables.values.flatMap {
                $0.map { $0.type.signalType.bits }
            }
        // <execute_on_entry> + <state_bits> + <external_signals> + <machine_signals> + <state_signals> 
        //     + <observed>
        return bits.reduce(self.numberOfStateBits + 2, +)
    }

    /// The size of an encoded target state.
    @inlinable var targetStateSize: VectorSize {
        VectorSize.downto(
            upper: .literal(value: .integer(value: max(targetStateBits - 1, 0))),
            lower: .literal(value: .integer(value: 0))
        )
    }

    /// The type of a single encoded target state.
    @inlinable var targetStateEncoding: SignalType {
        .ranged(type: .stdLogicVector(size: targetStateSize))
    }

    @inlinable
    func isTransitionReachable(from state: Int, transition: Transition) -> Bool {
        guard transition.source != state else {
            return true
        }
        return transitions.filter {
            $0.target == transition.source && $0.source != transition.source
        }
        .contains {
            isTransitionReachable(from: state, transition: $0)
        }
    }

    @inlinable
    func isTransitionReachable(from state: State, transition: Transition) -> Bool {
        guard let index = self.states.firstIndex(of: state) else {
            return false
        }
        return isTransitionReachable(from: index, transition: transition)
    }

}
