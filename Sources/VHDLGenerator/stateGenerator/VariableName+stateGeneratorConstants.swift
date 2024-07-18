// VariableName+stateGeneratorConstants.swift
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

import VHDLParsing

extension VariableName {

    /// The `AddToStates` constant.
    @usableFromInline static let addToStates = VariableName(rawValue: "AddToStates")!

    /// The `cacheBusy` signal.
    @usableFromInline static let cacheBusy = VariableName(rawValue: "cacheBusy")!

    /// The `cacheRead` signal.
    @usableFromInline static let cacheRead = VariableName(rawValue: "cacheRead")!

    /// The `CheckForDuplicates` constant.
    @usableFromInline static let checkForDuplicates = VariableName(rawValue: "CheckForDuplicates")!

    /// The `CheckForJob` constant.
    @usableFromInline static let checkForJob = VariableName(rawValue: "CheckForJob")!

    /// The `genRead` signal.
    @usableFromInline static let genRead = VariableName(rawValue: "genRead")!

    /// The `genReady` signal.
    @usableFromInline static let genReady = VariableName(rawValue: "genReady")!

    /// The `hasDuplicate` signal.
    @usableFromInline static let hasDuplicate = VariableName(rawValue: "hasDuplicate")!

    /// The `ResetStateIndex` constant.
    @usableFromInline static let resetStateIndex = VariableName(rawValue: "ResetStateIndex")!

    /// The `runnerBusy` signal.
    @usableFromInline static let runnerBusy = VariableName(rawValue: "runnerBusy")!

    /// The `startCache` signal.
    @usableFromInline static let startCache = VariableName(rawValue: "startCache")!

    /// The `startGeneration` signal.
    @usableFromInline static let startGeneration = VariableName(rawValue: "startGeneration")!

    /// The `states` signal.
    @usableFromInline static let states = VariableName(rawValue: "states")!

    /// The `statesIndex` signal.
    @usableFromInline static let statesIndex = VariableName(rawValue: "statesIndex")!

    /// The `targetStates` signal.
    @usableFromInline static let targetStates = VariableName(rawValue: "targetStates")!

    /// The `WaitForCacheToEnd` constant.
    @usableFromInline static let waitForCacheToEnd = VariableName(rawValue: "WaitForCacheToEnd")!

    /// The `WaitForCacheToStart` constant.
    @usableFromInline static let waitForCacheToStart = VariableName(rawValue: "WaitForCacheToStart")!

    // The `WaitForRunnerToFinish` constant.
    @usableFromInline static let waitForRunnerToFinish = VariableName(rawValue: "WaitForRunnerToFinish")!

    /// The `WaitForRunnerToStart` constant.
    @usableFromInline static let waitForRunnerToStart = VariableName(rawValue: "WaitForRunnerToStart")!

}
