// VariableName+generatorConstants.swift
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

    /// The `CheckForDuplicate` constant.
    @usableFromInline static let checkForDuplicate = VariableName(rawValue: "CheckForDuplicate")!

    /// The `CheckIfFinished` constant.
    @usableFromInline static let checkIfFinished = VariableName(rawValue: "CheckIfFinished")!

    /// The `ChooseNextInsertion` constant.
    @usableFromInline static let chooseNextInsertion = VariableName(rawValue: "ChooseNextInsertion")!

    /// The `fromState` signal.
    @usableFromInline static let fromState = VariableName(rawValue: "fromState")!

    /// The `HasFinished` signal.
    @usableFromInline static let hasFinished = VariableName(rawValue: "HasFinished")!

    /// The `isFinished` signal.
    @usableFromInline static let isFinished = VariableName(rawValue: "isFinished")!

    /// The `maxInsertIndex` signal.
    @usableFromInline static let maxInsertIndex = VariableName(rawValue: "maxInsertIndex")!

    /// The `observedIndex` signal.
    @usableFromInline static let observedIndex = VariableName(rawValue: "observedIndex")!

    /// The `observedStates` signal.
    @usableFromInline static let observedStates = VariableName(rawValue: "observedStates")!

    /// The `pendingInsertIndex` signal.
    @usableFromInline static let pendingInsertIndex = VariableName(rawValue: "pendingInsertIndex")!

    /// The `pendingStateIndex` signal.
    @usableFromInline static let pendingStateIndex = VariableName(rawValue: "pendingStateIndex")!

    /// The `SetJob` constant.
    @usableFromInline static let setJob = VariableName(rawValue: "SetJob")!

    /// The `VerifyDuplicate` constant.
    @usableFromInline static let verifyDuplicate = VariableName(rawValue: "VerifyDuplicate")!

    /// The `VerifyFinished` constant.
    @usableFromInline static let verifyFinished = VariableName(rawValue: "VerifyFinished")!

}
