// PortSignal+internalVariables.swift
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

/// Adds the ability to create port signals required for kripke structure generation in a specific machine.
extension PortSignal {

    /// The `reset` signal.
    @usableFromInline static let reset = PortSignal(type: .stdLogic, name: .reset, mode: .input)

    /// The `setInternalSignals` signal.
    @usableFromInline static let setInternalSignals = PortSignal(
        type: .stdLogic, name: .setInternalSignals, mode: .input
    )

    /// The `clk` signal.
    @usableFromInline static let clk = PortSignal(type: .stdLogic, name: .clk, mode: .input)

    /// Create the `currentStateIn` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(currentStateInFor representation: T) where T: MachineVHDLRepresentable {
        self.init(name: .currentStateIn(for: representation), machine: representation.machine, mode: .input)
    }

    /// Create the `currentStateOut` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(currentStateOutFor representation: T) where T: MachineVHDLRepresentable {
        self.init(name: .currentStateOut(for: representation), machine: representation.machine, mode: .output)
    }

    /// Create the `internalStateIn` signal for a machine.
    /// - Parameter machine: The representation to create the signal for.
    @usableFromInline
    init?<T>(internalStateInFor representation: T) where T: MachineVHDLRepresentable {
        self.init(name: .internalStateIn(for: representation), bitsRequired: 3, mode: .input)
    }

    /// Create the `internalStateOut` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(internalStateOutFor representation: T) where T: MachineVHDLRepresentable {
        self.init(name: .internalStateOut(for: representation), bitsRequired: 3, mode: .output)
    }

    /// Create the `previousRingletIn` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(previousRingletInFor representation: T) where T: MachineVHDLRepresentable {
        self.init(
            name: .previousRingletIn(for: representation), machine: representation.machine, mode: .input
        )
    }

    /// Create the `previousRingletOut` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(previousRingletOutFor representation: T) where T: MachineVHDLRepresentable {
        self.init(
            name: .previousRingletOut(for: representation), machine: representation.machine, mode: .output
        )
    }

    /// Create the `targetStateIn` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(targetStateInFor representation: T) where T: MachineVHDLRepresentable {
        self.init(name: .targetStateIn(for: representation), machine: representation.machine, mode: .input)
    }

    /// Create the `targetStateOut` signal for a machine.
    /// - Parameter representation: The machine to create the signal for.
    @inlinable
    init?<T>(targetStateOutFor representation: T) where T: MachineVHDLRepresentable {
        self.init(name: .targetStateOut(for: representation), machine: representation.machine, mode: .output)
    }

    /// Create a `std_logic_vector` port signal.
    /// - Parameters:
    ///   - name: The name of the signal.
    ///   - bitsRequired: The number of bits in the signal.
    ///   - mode: The mode of the signal.
    /// - Warning: `bitsRequired` must be greater than 0. Values that are 0 or less will cause a fatal error.
    @inlinable
    init(name: VariableName, bitsRequired: Int, mode: Mode) {
        guard bitsRequired > 0 else {
            fatalError("Invalid number of bits.")
        }
        self.init(
            type: .ranged(type: .stdLogicVector(size: .downto(
                upper: .literal(value: .integer(value: bitsRequired - 1)),
                lower: .literal(value: .integer(value: 0))
            ))),
            name: name,
            mode: mode
        )
    }

    /// Create a PortSignal that is sized to fit the number of states in a machine.
    /// - Parameters:
    ///   - name: The name of the signal.
    ///   - machine: The machine containing the states.
    ///   - mode: The mode of the signal.
    @inlinable
    init?(name: VariableName, machine: Machine, mode: Mode) {
        guard
            let bitsRequired = BitLiteral.bitsRequired(for: machine.states.count - 1), bitsRequired >= 1
        else {
            return nil
        }
        self.init(name: name, bitsRequired: bitsRequired, mode: mode)
    }

    /// Creates a `PortSignal` for an equivalent `LocalSignal` that exists within a `Machine`.
    /// - Parameters:
    ///   - signal: The signal to convert.
    ///   - machine: The machine containing the signal.
    ///   - mode: The mode of the new `PortSignal`.
    /// - Warning: This init returns `nil` for signals containing alias types.
    @inlinable
    init?<T>(signal: LocalSignal, in representation: T, mode: Mode) where T: MachineVHDLRepresentable {
        guard case .signal(let type) = signal.type else {
            return nil
        }
        let name = VariableName(portNameFor: signal, in: representation)
        self.init(type: type, name: name, mode: mode)
    }

}
