// VariableName+signalNames.swift
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

/// Adds common variable names.
extension VariableName {

    // swiftlint:disable force_unwrapping

    /// The `clk` signal.
    @usableFromInline static let clk = VariableName(rawValue: "clk")!

    /// The `currentState` signal.
    @usableFromInline static let currentState = VariableName(rawValue: "currentState")!

    /// The `Executing` constant.
    @usableFromInline static let executing = VariableName(rawValue: "Executing")!

    /// The `finished` signal.
    @usableFromInline static let finished = VariableName(rawValue: "finished")!

    /// The `goalInternal` signal.
    @usableFromInline static let goalInternal = VariableName(rawValue: "goalInternal")!

    /// The `goalInternalState` signal.
    @usableFromInline static let goalInternalState = VariableName(rawValue: "goalInternalState")!

    /// The `internalState` signal.
    @usableFromInline static let internalState = VariableName(rawValue: "internalState")!

    /// The `previousRinglet` signal.
    @usableFromInline static let previousRinglet = VariableName(rawValue: "previousRinglet")!

    /// The `PrimitiveTypes` package name.
    @usableFromInline static let primitiveTypes = VariableName(rawValue: "PrimitiveTypes")!

    /// The `reset` signal.
    @usableFromInline static let reset = VariableName(rawValue: "reset")!

    /// The `rst` signal.
    @usableFromInline static let rst = VariableName(rawValue: "rst")!

    /// The `setInternalSignals` signal.
    @usableFromInline static let setInternalSignals = VariableName(rawValue: "setInternalSignals")!

    /// The `StartExecuting` constant.
    @usableFromInline static let startExecuting = VariableName(rawValue: "StartExecuting")!

    /// The `stateTracker` signal.
    @usableFromInline static let stateTracker = VariableName(rawValue: "stateTracker")!

    /// The `stdLogicTypes` constant.
    @usableFromInline static let stdLogicTypes = VariableName(rawValue: "stdLogicTypes")!

    /// The `stdLogicTypes_t` type.
    @usableFromInline static let stdLogicTypesT = VariableName(rawValue: "stdLogicTypes_t")!

    /// The `targetState` signal.
    @usableFromInline static let targetState = VariableName(rawValue: "targetState")!

    /// The `WaitForFinish` signal.
    @usableFromInline static let waitForFinish = VariableName(rawValue: "WaitForFinish")!

    /// The `WaitToStart` constant.
    @usableFromInline static let waitToStart = VariableName(rawValue: "WaitToStart")!

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

    // swiftlint:enable force_unwrapping

}
