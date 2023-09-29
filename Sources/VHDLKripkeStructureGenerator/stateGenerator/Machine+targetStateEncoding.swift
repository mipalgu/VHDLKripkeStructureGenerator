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

extension Machine {

    @inlinable var numberOfTargetStates: Int {
        let numberOfExternalValues = self.externalSignals.filter { $0.mode != .input }
            .map { $0.type.signalType.numberOfValues }
        let groupedTransitions = self.transitionsGroupedBySources
        let valuesPerState = Dictionary(uniqueKeysWithValues: groupedTransitions.map { state, transitions in
            let hasState = transitions.contains { self.transitionHasTarget(transition: $0, target: state) }
            guard self.states[self.initialState] != state else {
                return (state, max(1, hasState ? transitions.count : transitions.count + 1))
            }
            guard let suspendedState = self.suspendedState, state == self.states[suspendedState] else {
                return (state, hasState ? transitions.count : transitions.count + 1)
            }
            return (state, max(1, hasState ? transitions.count : transitions.count + 1))
        })
        let values = self.states.map {
            guard let valueForState = valuesPerState[$0] else {
                return 0
            }
            let numberOfValues = numberOfExternalValues + self.machineSignals.map {
                $0.type.signalType.numberOfValues
            } + self.stateVariables.values.flatMap {
                $0.map { $0.type.signalType.numberOfValues }
            } * 2
            return numberOfValues.reduce(valueForState, *)
        }
        return values.reduce(1, *)
    }

    @inlinable var targetStateBits: Int {
        let bits: [Int] = self.externalSignals.filter { $0.mode != .input }
            .map { $0.type.signalType.encodedBits } +
            self.machineSignals.map { $0.type.signalType.encodedBits } +
            self.stateVariables.values.flatMap {
                $0.map { $0.type.signalType.encodedBits }
            }
        return bits.reduce(0, +) + 3
    }

    @inlinable var targetStateSize: VectorSize {
        VectorSize.to(
            lower: .literal(value: .integer(value: 0)),
            upper: .literal(value: .integer(value: max(targetStateBits - 1, 0)))
        )
    }

    @inlinable var targetStateEncoding: SignalType {
        .ranged(type: .stdLogicVector(size: targetStateSize))
    }

    @inlinable var transitionsGroupedBySources: [State: [Transition]] {
        var groupedTransitions: [State: [Transition]] = [:]
        self.transitions.forEach {
            let state = self.states[$0.source]
            guard let currentValue = groupedTransitions[state] else {
                groupedTransitions[state] = [$0]
                return
            }
            groupedTransitions[state] = currentValue + [$0]
        }
        return groupedTransitions
    }

    @inlinable
    func transitionHasTarget(transition: Transition, target: State) -> Bool {
        guard let index = self.states.firstIndex(of: target) else {
            return false
        }
        return transition.target == index
    }

}
