// VariableName+ringletCacheConstants.swift
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

// swiftlint:disable force_unwrapping

/// A variable names for ringlet cache.
extension VariableName {

    /// The `cacheValue` signal.
    public static let cacheValue = VariableName(rawValue: "cacheValue")!

    /// The `CheckPreviousRinglets` constant.
    public static let checkPreviousRinglets = VariableName(rawValue: "CheckPreviousRinglets")!

    /// The `currentRinglet` signal.
    public static let currentRinglet = VariableName(rawValue: "currentRinglet")!

    /// The `currentRingletAddress` signal.
    public static let currentRingletAddress = VariableName(rawValue: "currentRingletAddress")!

    /// The `currentRingletIndex` signal.
    public static let currentRingletIndex = VariableName(rawValue: "currentRingletIndex")!

    /// The `CurrentRinglet_t` type.
    public static let currentRingletType = VariableName(rawValue: "CurrentRinglet_t")!

    /// The `Error` constant.
    public static let error = VariableName(rawValue: "Error")!

    /// The `genIndex` signal.
    public static let genIndex = VariableName(rawValue: "genIndex")!

    /// The `genValue` signal.
    public static let genValue = VariableName(rawValue: "genValue")!

    /// The `index` signal.
    public static let index = VariableName(rawValue: "index")!

    /// The `isDuplicate` signal.
    public static let isDuplicate = VariableName(rawValue: "isDuplicate")!

    /// The `isInitial` signal.
    public static let isInitial = VariableName(rawValue: "isInitial")!

    /// The `lastAccessibleAddress` constant.
    public static let lastAccessibleAddress = VariableName(rawValue: "lastAccessibleAddress")!

    /// The `memoryIndex` signal.
    public static let memoryIndex = VariableName(rawValue: "memoryIndex")!

    /// The `previousReadAddress` signal.
    public static let previousReadAddress = VariableName(rawValue: "previousReadAddress")!

    /// The `ringletIndex` signal.
    public static let ringletIndex = VariableName(rawValue: "ringletIndex")!

    /// The `SetRingletRAMValue` constant.
    public static let setRingletRAMValue = VariableName(rawValue: "SetRingletRAMValue")!

    /// The `SetRingletValue` constant.
    public static let setRingletValue = VariableName(rawValue: "SetRingletValue")!

    /// The `topIndex` signals.
    public static let topIndex = VariableName(rawValue: "topIndex")!

    /// The `WaitForNewRinglets` constant.
    public static let waitForNewRinglets = VariableName(rawValue: "WaitForNewRinglets")!

    /// The `WriteElement` constant.
    public static let writeElement = VariableName(rawValue: "WriteElement")!

    /// The `workingRinglets` signal.
    public static let workingRinglets = VariableName(rawValue: "workingRinglets")!

}

// swiftlint:enable force_unwrapping
