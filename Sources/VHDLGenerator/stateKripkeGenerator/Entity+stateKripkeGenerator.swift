// Entity+stateGenerator.swift
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

/// Add a states kripke generator.
extension Entity {

    /// Create the entity declaration for a states kripke generator.
    /// - Parameters:
    ///   - state: The state to generate this entity for.
    ///   - representation: The representation of the machine.
    @inlinable
    init?<T>(stateKripkeGeneratorFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        guard
            let name = VariableName(rawValue: "\(state.name.rawValue)KripkeGenerator"),
            let readSnapshot = VariableName(rawValue: "readSnapshot"),
            let writeSnapshot = VariableName(rawValue: "writeSnapshot")
        else {
            return nil
        }
        let machine = representation.machine
        guard machine.drivingClock >= 0, machine.drivingClock < machine.clocks.count else {
            return nil
        }
        let clock = machine.clocks[machine.drivingClock]
        guard let writeSnapshotSize = Record(writeSnapshotFor: state, in: representation)?.types.reduce(0, {
            guard case .signal(let type) = $1.type else {
                fatalError("Cannot determine size of \($1.type.rawValue)")
            }
            return $0 + type.bits
        }) else {
            return nil
        }
        let pendingStateSize = writeSnapshotSize + 1
        let pendingStateType = Type.signal(type: .ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: pendingStateSize - 1)),
            lower: .literal(value: .integer(value: 0))
        ))))
        // swiftlint:disable force_unwrapping
        self.init(name: name, port: PortBlock(signals: [
            PortSignal(clock: clock),
            PortSignal(type: .alias(name: .readSnapshotType), name: readSnapshot, mode: .input),
            PortSignal(type: .alias(name: .writeSnapshotType), name: writeSnapshot, mode: .input),
            PortSignal(
                type: .alias(name: VariableName(pre: "\(state.name.rawValue)_", name: .ringletType)!),
                name: .ringlet,
                mode: .output
            ),
            PortSignal(type: pendingStateType, name: .pendingState, mode: .output)
        ])!)
        // swiftlint:enable force_unwrapping
    }

}
