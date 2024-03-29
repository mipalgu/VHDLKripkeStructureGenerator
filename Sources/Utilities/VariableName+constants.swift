// VariableName+constants.swift
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

public extension VariableName {

    /// The `boolToStdLogic` function.
    static let boolToStdLogic = VariableName(rawValue: "boolToStdLogic")!

    /// The `currentState` signal.
    static let currentState = VariableName(rawValue: "currentState")!

    /// The `currentStateIn` signal.
    static let currentStateIn = VariableName(rawValue: "currentStateIn")!

    /// The `currentStateOut` signal.
    static let currentStateOut = VariableName(rawValue: "currentStateOut")!

    /// The `executeOnEntry` signal.
    static let executeOnEntry = VariableName(rawValue: "executeOnEntry")!

    /// The `finished` signal.
    static let finished = VariableName(rawValue: "finished")!

    /// The `goalInternalState` signal.
    static let goalInternalState = VariableName(rawValue: "goalInternalState")!

    /// The `internalState` signal.
    static let internalState = VariableName(rawValue: "internalState")!

    /// The `internalStateIn` signal.
    static let internalStateIn = VariableName(rawValue: "internalStateIn")!

    /// The `internalStateOut` signal.
    static let internalStateOut = VariableName(rawValue: "internalStateOut")!

    /// The `nextState` signal.
    static let nextState = VariableName(rawValue: "nextState")!

    /// The `observed` signal.
    static let observed = VariableName(rawValue: "observed")!

    /// The `previousRingletIn` signal.
    static let previousRingletIn = VariableName(rawValue: "previousRingletIn")!

    /// The `previousRingletOut` signal.
    static let previousRingletOut = VariableName(rawValue: "previousRingletOut")!

    /// The `ReadSnapshot_t` type.
    static let readSnapshotType = VariableName(rawValue: "ReadSnapshot_t")!

    /// The `reset` signal.
    static let reset = VariableName(rawValue: "reset")!

    /// The `ringlet_counter` signal.
    static let ringletCounter = VariableName(rawValue: "ringlet_counter")!

    /// The `Ringlet_t` type.
    static let ringletType = VariableName(rawValue: "Ringlet_t")!

    /// The `state` signal.
    static let state = VariableName(rawValue: "state")!

    /// The `State_Execution_t` type.
    static let stateExecutionType = VariableName(rawValue: "State_Execution_t")!

    /// The `stdLogicToBool` function.
    static let stdLogicToBool = VariableName(rawValue: "stdLogicToBool")!

    /// The `targetStateIn` signal.
    static let targetStateIn = VariableName(rawValue: "targetStateIn")!

    /// The `targetStateOut` signal.
    static let targetStateOut = VariableName(rawValue: "targetStateOut")!

    /// The `to_integer` function.
    static let toInteger = VariableName(rawValue: "to_integer")!

    /// The `to_signed` function.
    static let toSigned = VariableName(rawValue: "to_signed")!

    /// The `TotalSnapshot_t` record.
    static let totalSnapshot = VariableName(rawValue: "TotalSnapshot_t")!

    /// The `to_unsigned` function.
    static let toUnsigned = VariableName(rawValue: "to_unsigned")!

    /// The `WriteSnapshot_t` type.
    static let writeSnapshotType = VariableName(rawValue: "WriteSnapshot_t")!

    /// Appends a string to the end of a `VariableName`.
    /// - Parameters:
    ///   - name: The name to modify.
    ///   - post: The string to append to the end of `name`.
    @inlinable
    init?(name: VariableName, post: String) {
        self.init(rawValue: "\(name.rawValue)\(post)")
    }

    /// Creates the equivalent port name for a signal that exists within a machines local scope. The new name
    /// namespaces the machine before the signal name.
    /// - Parameters:
    ///   - signal: The signal to convert to a port name.
    ///   - machine: The machine that uses this signal.
    @inlinable
    init(portNameFor signal: LocalSignal, in machine: Machine) {
        self.init(rawValue: "\(machine.name)_\(signal.name)")!
    }

    /// Prepends a string to the start of a `VariableName`.
    /// - Parameters:
    ///   - pre: The string to prepend.
    ///   - name: The `VariableName` to modify.
    @inlinable
    init?(pre: String, name: VariableName) {
        self.init(rawValue: "\(pre)\(name.rawValue)")
    }

    /// Adds strings to the beginning and end of a `VariableName`.
    /// - Parameters:
    ///   - pre: The string to prepend to `name`.
    ///   - name: The `VariableName` to modify.
    ///   - post: The string to append to `name`.
    @inlinable
    init?(pre: String, name: VariableName, post: String) {
        self.init(rawValue: "\(pre)\(name.rawValue)\(post)")
    }

    /// The `setTargetState` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func currentStateIn(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_currentStateIn")!
    }

    /// The `currentStateOut` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func currentStateOut(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_currentStateOut")!
    }

    /// The `internalStateIn` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func internalStateIn(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_internalStateIn")!
    }

    /// The `internalStateOut` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func internalStateOut(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_internalStateOut")!
    }

    /// The `previousRingletIn` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func previousRingletIn(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_previousRingletIn")!
    }

    /// The `previousRingletOut` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func previousRingletOut(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_previousRingletOut")!
    }

    /// The `targetStateIn` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func targetStateIn(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_targetStateIn")!
    }

    /// The `targetStateOut` signal.
    /// - Parameter machine: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func targetStateOut(for machine: Machine) -> VariableName {
        VariableName(rawValue: "\(machine.name)_targetStateOut")!
    }

}
