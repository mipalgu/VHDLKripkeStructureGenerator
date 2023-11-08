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

    /// The `addr` signal.
    @usableFromInline static let addr = VariableName(rawValue: "addr")!

    /// The `Behavioral` name.
    @usableFromInline static let behavioral = VariableName(rawValue: "Behavioral")!

    /// The `bitTypes` constant.
    @usableFromInline static let bitTypes = VariableName(rawValue: "bitTypes")!

    /// The `BitTypes_t` type.
    @usableFromInline static let bitTypesT = VariableName(rawValue: "BitTypes_t")!

    /// The `booleanTypes` constant.
    @usableFromInline static let booleanTypes = VariableName(rawValue: "booleanTypes")!

    /// The `BooleanTypes_t` type.
    @usableFromInline static let booleanTypesT = VariableName(rawValue: "BooleanTypes_t")!

    /// The `busy` signal.
    @usableFromInline static let busy = VariableName(rawValue: "busy")!

    /// The `clk` signal.
    @usableFromInline static let clk = VariableName(rawValue: "clk")!

    /// The `currentExecuteOnEntry` signal.
    @usableFromInline static let currentExecuteOnEntry = VariableName(rawValue: "currentExecuteOnEntry")!

    /// The `di` signal.
    @usableFromInline static let di = VariableName(rawValue: "di")!

    /// The `do` signal.
    @usableFromInline static let `do` = VariableName(rawValue: "do")!

    /// The `encodedToStdLogic` function.
    @usableFromInline static let encodedToStdLogic = VariableName(rawValue: "encodedToStdLogic")!

    /// The `encodedToStdULogic` function.
    @usableFromInline static let encodedToStdULogic = VariableName(rawValue: "encodedToStdULogic")!

    /// The `Executing` constant.
    @usableFromInline static let executing = VariableName(rawValue: "Executing")!

    /// The `Finished_t` type.
    @usableFromInline static let finishedType = VariableName(rawValue: "Finished_t")!

    /// The `goalInternal` signal.
    @usableFromInline static let goalInternal = VariableName(rawValue: "goalInternal")!

    /// The `hasStarted` signal.
    @usableFromInline static let hasStarted = VariableName(rawValue: "hasStarted")!

    /// The `i` signal.
    @usableFromInline static let i = VariableName(rawValue: "i")!

    /// The `IEEE` library.
    @usableFromInline static let ieee = VariableName(rawValue: "IEEE")!

    /// The `lastAddress` signal.
    @usableFromInline static let lastAddress = VariableName(rawValue: "lastAddress")!

    /// The `machine` signal.
    @usableFromInline static let machine = VariableName(rawValue: "machine")!

    /// The `newRinglets` signal.
    @usableFromInline static let newRinglets = VariableName(rawValue: "newRinglets")!

    /// The `pendingState` signal.
    @usableFromInline static let pendingState = VariableName(rawValue: "pendingState")!

    /// The `pendingStates` signal.
    @usableFromInline static let pendingStates = VariableName(rawValue: "pendingStates")!

    /// The `Pending_States_t` type.
    @usableFromInline static let pendingStatesType = VariableName(rawValue: "Pending_States_t")!

    /// The `previousRinglet` signal.
    @usableFromInline static let previousRinglet = VariableName(rawValue: "previousRinglet")!

    /// The `PrimitiveTypes` package name.
    @usableFromInline static let primitiveTypes = VariableName(rawValue: "PrimitiveTypes")!

    /// The `ram` signal.
    @usableFromInline static let ram = VariableName(rawValue: "ram")!

    /// The `Raw_t` type.
    @usableFromInline static let rawType = VariableName(rawValue: "Raw_t")!

    /// The `readAddress` signal.
    @usableFromInline static let readAddress = VariableName(rawValue: "readAddress")!

    /// The `readSnapshot` signal.
    @usableFromInline static let readSnapshotSignal = VariableName(rawValue: "readSnapshot")!

    /// The `ReadSnapshot` constant.
    @usableFromInline static let readSnapshot = VariableName(rawValue: "ReadSnapshot")!

    /// The `readSnapshots` signal.
    @usableFromInline static let readSnapshots = VariableName(rawValue: "readSnapshots")!

    /// The `readSnapshotState` signal.
    @usableFromInline static let readSnapshotState = VariableName(rawValue: "readSnapshotState")!

    /// The `ReadSnapshots_t` type.
    @usableFromInline static let readSnapshotsType = VariableName(rawValue: "ReadSnapshots_t")!

    /// The `read` signal.
    @usableFromInline static let read = VariableName(rawValue: "read")!

    /// The `ready` signal.
    @usableFromInline static let ready = VariableName(rawValue: "ready")!

    /// The `ringlet` signal.
    @usableFromInline static let ringlet = VariableName(rawValue: "ringlet")!

    /// The `ringlets` signal.
    @usableFromInline static let ringlets = VariableName(rawValue: "ringlets")!

    /// The `Ringlets_Working_t` type.
    @usableFromInline static let ringletsWorkingType = VariableName(rawValue: "Ringlets_Working_t")!

    /// The `rst` signal.
    @usableFromInline static let rst = VariableName(rawValue: "rst")!

    /// The `setInternalSignals` signal.
    @usableFromInline static let setInternalSignals = VariableName(rawValue: "setInternalSignals")!

    /// The `StartExecuting` constant.
    @usableFromInline static let startExecuting = VariableName(rawValue: "StartExecuting")!

    /// The `stateTracker` signal.
    @usableFromInline static let stateTracker = VariableName(rawValue: "stateTracker")!

    /// The `stdLogicEncoded` function.
    @usableFromInline static let stdLogicEncoded = VariableName(rawValue: "stdLogicEncoded")!

    /// The `stdLogicTypes` constant.
    @usableFromInline static let stdLogicTypes = VariableName(rawValue: "stdLogicTypes")!

    /// The `stdLogicTypes_t` type.
    @usableFromInline static let stdLogicTypesT = VariableName(rawValue: "stdLogicTypes_t")!

    /// The `stdULogicEncoded` function.
    @usableFromInline static let stdULogicEncoded = VariableName(rawValue: "stdULogicEncoded")!

    /// The `targets` signal.
    @usableFromInline static let targets = VariableName(rawValue: "targets")!

    /// The `Targets_t` type.
    @usableFromInline static let targetsType = VariableName(rawValue: "Targets_t")!

    /// The `targetState` signal.
    @usableFromInline static let targetState = VariableName(rawValue: "targetState")!

    /// The `TargetStates_t` type.
    @usableFromInline static let targetStatesType = VariableName(rawValue: "TargetStates_t")!

    /// The `tracker` signal.
    @usableFromInline static let tracker = VariableName(rawValue: "tracker")!

    /// the `value` variable.
    @usableFromInline static let value = VariableName(rawValue: "value")!

    /// The `vector` signal.
    @usableFromInline static let vector = VariableName(rawValue: "vector")!

    /// The `WaitForFinish` signal.
    @usableFromInline static let waitForFinish = VariableName(rawValue: "WaitForFinish")!

    /// The `WaitForMachineStart` constant.
    @usableFromInline static let waitForMachineStart = VariableName(rawValue: "WaitForMachineStart")!

    /// The `WaitForStart` constant.
    @usableFromInline static let waitForStart = VariableName(rawValue: "WaitForStart")!

    /// The `WaitToStart` constant.
    @usableFromInline static let waitToStart = VariableName(rawValue: "WaitToStart")!

    /// The `we` signal.
    @usableFromInline static let we = VariableName(rawValue: "we")!

    /// The `writeSnapshot` signal.
    @usableFromInline static let writeSnapshotSignal = VariableName(rawValue: "writeSnapshot")!

    /// The `WriteSnapshot` constant.
    @usableFromInline static let writeSnapshot = VariableName(rawValue: "WriteSnapshot")!

    /// The `writeSnapshots` signal.
    @usableFromInline static let writeSnapshots = VariableName(rawValue: "writeSnapshots")!

    /// The `writeSnapshotState` signal.
    @usableFromInline static let writeSnapshotState = VariableName(rawValue: "writeSnapshotState")!

    /// The `WriteSnapshots_t` type.
    @usableFromInline static let writeSnapshotsType = VariableName(rawValue: "WriteSnapshots_t")!

    // swiftlint:enable force_unwrapping

}
