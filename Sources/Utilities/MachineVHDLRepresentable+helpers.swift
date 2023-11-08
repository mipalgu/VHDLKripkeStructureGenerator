// MachineVHDLRepresentable+helpers.swift
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

public extension MachineVHDLRepresentable {

    /// Find all constants in the architecture head.
    @inlinable var allConstants: [HeadStatement] {
        self.architectureHead.statements.filter {
            guard case .definition(let def) = $0, case .constant = def else {
                return false
            }
            return true
        }
    }

    /// Returns all the external variables in the representation.
    @inlinable var externalVariables: [PortSignal] {
        self.entity.port.signals.filter {
            $0.name.rawValue.lowercased().hasPrefix("external_")
        }
    }

    /// Get type of state array.
    @inlinable var stateType: SignalType? {
        let currentStateSignal: LocalSignal? = self.architectureHead.statements.lazy
            .compactMap { (statement: HeadStatement) -> LocalSignal? in
                guard
                    case .definition(let def) = statement,
                    case .signal(let signal) = def
                else {
                    return nil
                }
                return signal
            }
            .first { $0.name == .currentState }
        guard case .signal(let type) = currentStateSignal?.type else {
            return nil
        }
        return type
    }

    /// The number of bits in the state encoding.
    @inlinable var numberOfStateBits: Int? {
        self.architectureHead.statements.lazy.compactMap {
            guard
                case .definition(let def) = $0,
                case .signal(let signal) = def,
                signal.name == .currentState,
                case .signal(let type) = signal.type,
                case .ranged(let vec) = type
            else {
                return nil
            }
            return vec.size.size
        }
        .first
    }

}
