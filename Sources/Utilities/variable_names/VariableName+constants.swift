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

/// Add constants.
public extension VariableName {

    /// The `boolToStdLogic` function.
    static let boolToStdLogic = VariableName(rawValue: "boolToStdLogic")!

    /// The `cache` signal.
    static let cache = VariableName(rawValue: "cache")!

    /// The `cacheIndex` signal.
    static let cacheIndex = VariableName(rawValue: "cacheIndex")!

    /// The `cache_inst` label.
    static let cacheInst = VariableName(rawValue: "cache_inst")!

    /// The `ChooseAccess` case.
    static let chooseAccess = VariableName(rawValue: "ChooseAccess")!

    /// The `currentIndex` signal.
    static let currentIndex = VariableName(rawValue: "currentIndex")!

    /// The `currentState` signal.
    static let currentState = VariableName(rawValue: "currentState")!

    /// The `currentStateIn` signal.
    static let currentStateIn = VariableName(rawValue: "currentStateIn")!

    /// The `currentStateOut` signal.
    static let currentStateOut = VariableName(rawValue: "currentStateOut")!

    /// The `data` signal.
    static let data = VariableName(rawValue: "data")!

    /// The `denominator` signal.
    static let denominator = VariableName(rawValue: "denominator")!

    /// The `divisor` signal.
    static let divisor = VariableName(rawValue: "divisor")!

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

    /// The `lastEnabled` signal.
    static let lastEnabled = VariableName(rawValue: "lastEnabled")!

    /// The `nextState` signal.
    static let nextState = VariableName(rawValue: "nextState")!

    /// The `numerator` signal.
    static let numerator = VariableName(rawValue: "numerator")!

    /// The `observed` signal.
    static let observed = VariableName(rawValue: "observed")!

    /// The `previousRingletIn` signal.
    static let previousRingletIn = VariableName(rawValue: "previousRingletIn")!

    /// The `previousRingletOut` signal.
    static let previousRingletOut = VariableName(rawValue: "previousRingletOut")!

    /// The `readCache` signal.
    static let readCache = VariableName(rawValue: "readCache")!

    /// The `readEnable` signal.
    static let readEnable = VariableName(rawValue: "readEnable")!

    /// The `ReadSnapshot_t` type.
    static let readSnapshotType = VariableName(rawValue: "ReadSnapshot_t")!

    /// The `readValue` signal.
    static let readValue = VariableName(rawValue: "readValue")!

    /// The `remainder` signal.
    static let remainder = VariableName(rawValue: "remainder")!

    /// The `reset` signal.
    static let reset = VariableName(rawValue: "reset")!

    /// The `resize` function.
    static let resize = VariableName(rawValue: "resize")!

    /// The `result` signal.
    static let result = VariableName(rawValue: "result")!

    /// The `ringlet_counter` signal.
    static let ringletCounter = VariableName(rawValue: "ringlet_counter")!

    /// The `Ringlet_t` type.
    static let ringletType = VariableName(rawValue: "Ringlet_t")!

    /// The `SetNextRinglet` constant.
    static let setNextRinglet = VariableName(rawValue: "SetNextRinglet")!

    /// The `SetNextTargetState` constant.
    static let setNextTargetState = VariableName(rawValue: "SetNextTargetState")!

    /// The `shift_right` function.
    static let shiftRight = VariableName(rawValue: "shift_right")!

    /// The `state` signal.
    static let state = VariableName(rawValue: "state")!

    /// The `State_Execution_t` type.
    static let stateExecutionType = VariableName(rawValue: "State_Execution_t")!

    /// The `stdLogicToBool` function.
    static let stdLogicToBool = VariableName(rawValue: "stdLogicToBool")!

    /// The `targetStateIn` signal.
    static let targetStateIn = VariableName(rawValue: "targetStateIn")!

    /// The `TargetStatesBRAM_t` type.
    static let targetStatesBRAMType = VariableName(rawValue: "TargetStatesBRAM_t")!

    /// The `TargetStatesBRAMElement_t` type.
    static let targetStatesBRAMElementType = VariableName(rawValue: "TargetStatesBRAMElement_t")!

    /// The `TargetStatesBRAMEnabled_t` type.
    static let targetStatesBRAMEnabledType = VariableName(rawValue: "TargetStatesBRAMEnabled_t")!

    /// The `TargetStatesCacheMonitor`.
    static let targetStatesCacheMonitor = VariableName(rawValue: "TargetStatesCacheMonitor")!

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

    /// The `unsignedAddress` signal.
    static let unsignedAddress = VariableName(rawValue: "unsignedAddress")!

    /// The `unsignedLastAddress` signal.
    static let unsignedLastAddress = VariableName(rawValue: "unsignedLastAddress")!

    /// The `value_en` signal.
    static let valueEn = VariableName(rawValue: "value_en")!

    /// The `WaitForAccess` case.
    static let waitForAccess = VariableName(rawValue: "WaitForAccess")!

    /// The `WaitWhileBusy` case.
    static let waitWhileBusy = VariableName(rawValue: "WaitWhileBusy")!

    /// The `WaitForNewData` type.
    static let waitForNewDataType = VariableName(rawValue: "WaitForNewData")!

    /// The `WaitForRead` constant.
    static let waitForRead = VariableName(rawValue: "WaitForRead")!

    /// The `WaitForReadEnable` constant.
    static let waitForReadEnable = VariableName(rawValue: "WaitForReadEnable")!

    /// The `WriteSnapshot_t` type.
    static let writeSnapshotType = VariableName(rawValue: "WriteSnapshot_t")!

    /// The `ZERO` constant.
    static let zero = VariableName(rawValue: "ZERO")!

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
    ///   - representation: The machine that uses this signal.
    @inlinable
    init<T>(portNameFor signal: LocalSignal, in representation: T) where T: MachineVHDLRepresentable {
        self.init(rawValue: "\(representation.entity.name)_\(signal.name)")!
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
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func currentStateIn<T>(for representation: T) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_currentStateIn")!
    }

    /// The `currentStateOut` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func currentStateOut<T>(for representation: T) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_currentStateOut")!
    }

    /// The `internalStateIn` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func internalStateIn<T>(for representation: T) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_internalStateIn")!
    }

    /// The `internalStateOut` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func internalStateOut<T>(
        for representation: T
    ) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_internalStateOut")!
    }

    /// The `previousRingletIn` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func previousRingletIn<T>(
        for representation: T
    ) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_previousRingletIn")!
    }

    /// The `previousRingletOut` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func previousRingletOut<T>(
        for representation: T
    ) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_previousRingletOut")!
    }

    /// The `targetStateIn` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func targetStateIn<T>(for representation: T) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_targetStateIn")!
    }

    /// The `targetStateOut` signal.
    /// - Parameter representation: The machine that uses this signal.
    /// - Returns: The variable name for this signal.
    @inlinable
    static func targetStateOut<T>(for representation: T) -> VariableName where T: MachineVHDLRepresentable {
        VariableName(rawValue: "\(representation.entity.name)_targetStateOut")!
    }

}
