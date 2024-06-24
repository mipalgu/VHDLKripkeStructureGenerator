// VariableName+targetStateCache.swift
// VHDLKripkeStructureGenerator
// 
// Created by Morgan McColl.
// Copyright © 2024 Morgan McColl. All rights reserved.
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

import VHDLParsing

// swiftlint:disable force_unwrapping

/// Add cache constants.
extension VariableName {

    /// The `currentValue` signal.
    @usableFromInline static let currentValue = VariableName(rawValue: "currentValue")!

    /// The `enables` signal.
    @usableFromInline static let enables = VariableName(rawValue: "enables")!

    /// The `IncrementIndex` signal.
    @usableFromInline static let incrementIndex = VariableName(rawValue: "IncrementIndex")!

    /// The `memoryAddress` signal.
    @usableFromInline static let memoryAddress = VariableName(rawValue: "memoryAddress")!

    /// The `memoryOffset` signal.
    @usableFromInline static let memoryOffset = VariableName(rawValue: "memoryOffset")!

    /// The `readEnables` signal.
    @usableFromInline static let readEnables = VariableName(rawValue: "readEnables")!

    /// The `readStates` signal.
    @usableFromInline static let readStates = VariableName(rawValue: "readStates")!

    /// The `resetEnables` signal.
    @usableFromInline static let resetEnables = VariableName(rawValue: "ResetEnables")!

    /// The `stateIndex` signal.
    @usableFromInline static let stateIndex = VariableName(rawValue: "stateIndex")!

    /// The `TargetStatesCache` signal.
    @usableFromInline static let targetStatesCache = VariableName(rawValue: "TargetStatesCache")!

    /// The `TargetStatesCache_InternalState_t` signal.
    @usableFromInline static let targetStatesCacheInternalStateType = VariableName(
        rawValue: "TargetStatesCache_InternalState_t"
    )!

    /// The `weBRAM` signal.
    @usableFromInline static let weBRAM = VariableName(rawValue: "weBRAM")!

    /// The `workingStates` signal.
    @usableFromInline static let workingStates = VariableName(rawValue: "workingStates")!

}

// swiftlint:enable force_unwrapping
