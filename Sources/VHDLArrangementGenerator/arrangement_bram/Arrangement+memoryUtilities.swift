// Arrangement+memoryUtilities.swift
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

import VHDLMachines
import VHDLParsing

extension Arrangement {

    func encodedSize(machines: [VariableName: any MachineVHDLRepresentable]) -> Int {
        let externalEncodedSize = self.externalSignals.reduce(0) {
            let bits = $1.type.signalType.encodedBits
            guard $1.mode != .input else {
                return $0 + bits
            }
            return $0 + bits * 2
        }
        let globalEncodedSize = self.signals.reduce(0) {
            $0 + $1.type.signalType.encodedBits * 2
        }
        let machineEncodedSize = self.machines.reduce(0) {
            let type = $1.key.type
            guard let machineRepresentation = machines[type] else {
                fatalError("Machine \(type) not found.")
            }
            let machine = machineRepresentation.machine
            let machineBits = machine.machineSignals.reduce(0) {
                $0 + $1.type.signalType.encodedBits * 2
            }
            let stateSignalBits: Int = machine.states.reduce(0) {
                $0 + $1.signals.reduce(0) {
                    $0 + $1.type.signalType.encodedBits * 2
                }
            }
            guard let stateBits = BitLiteral.bitsRequired(for: max(1, machine.states.count - 1)) else {
                fatalError("Too few states.")
            }
            return $0 + machineBits + stateSignalBits + stateBits * 2 + 2
        }
        return externalEncodedSize + globalEncodedSize + machineEncodedSize + 1
    }

    func numberOfValues(machines: [VariableName: any MachineVHDLRepresentable]) -> Int {
        let externalValues = self.externalSignals.reduce(1) {
            let numberOfValues = $1.type.signalType.numberOfValues
            guard $1.mode != .input else {
                return $0 * numberOfValues
            }
            return $0 * numberOfValues * 2
        }
        let globalValues = self.signals.reduce(1) {
            $0 * $1.type.signalType.numberOfValues * 2
        }
        let machineValues = self.machines.reduce(1) {
            let type = $1.key.type
            guard let machineRepresentation = machines[type] else {
                fatalError("Machine \(type) not found.")
            }
            let machine = machineRepresentation.machine
            let machineValues = machine.machineSignals.reduce(1) {
                $0 * $1.type.signalType.numberOfValues * 2
            }
            let stateValues = machine.states.reduce(1) {
                $0 * $1.signals.reduce(1) {
                    $0 * $1.type.signalType.numberOfValues * 2
                }
            }
            // carry + machine signals + state signals + state count * 2 (read/write)
            // + 2 executeOnEntry * 2(read/write)
            return $0 * machineValues * stateValues * machine.states.count * 2 * 4
        }
        return externalValues * globalValues * machineValues
    }

}
