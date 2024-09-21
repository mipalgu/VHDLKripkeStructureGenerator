// String+CTypes.swift
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

import StringHelpers
import Utilities
import VHDLMachines
import VHDLParsing

extension String {

    public init<T>(cTypesFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let externalVariables = [VariableName: PortSignal](
            uniqueKeysWithValues: machine.externalSignals.map { ($0.name, $0) }
        )
        let name = representation.entity.name.rawValue
        let machineVariableSize = machine.machineSignals
            .map { $0.type.signalType.encodedBits }.reduce(0, +)
        let stateSize = machine.numberOfStateBits
        let stateTypes = machine.states.map {
            String(
                machineName: name,
                cTypeForState: $0,
                externalVariables: externalVariables,
                machineVariablesSize: machineVariableSize,
                stateSize: stateSize
            )
        }
        let stateFunctions = machine.states.sorted { $0.name < $1.name }.flatMap {
            [
                VariableParser(state: $0, in: representation)
                    .definitions.sorted { $0.0 < $1.0 }.map { $0.1 }.joined(separator: "\n\n"),
                String(isValidStateDefinitionFor: $0, in: representation)
            ]
        }
        self = """
        #include <stdint.h>
        #include <stdbool.h>
        #ifndef \(name)_H
        #define \(name)_H
        #ifdef __cplusplus
        extern "C" {
        #endif
        \(stateTypes.joined(separator: "\n\n"))

        \(String(isValidDefinitionFor: representation))

        \(stateFunctions.joined(separator: "\n\n"))

        #ifdef __cplusplus
        }
        #endif

        #endif // \(name)_H

        """
    }

    init(
        machineName name: String,
        cTypeForState state: State,
        externalVariables: [VariableName: PortSignal],
        machineVariablesSize: Int,
        stateSize: Int
    ) {
        let readExternalSize = state.externalVariables.map {
            guard let bits = externalVariables[$0]?.type.signalType.encodedBits else {
                fatalError("External variable \($0) not found for state \(state.name)")
            }
            return bits
        }
        let externalSize = readExternalSize.reduce(0, +)
        let stateSize = state.signals.reduce(0) {
            $0 + $1.type.signalType.encodedBits
        }
        let readSnapshotSize = externalSize + stateSize + machineVariablesSize + 1 + stateSize
        let writeExternals: [Int] = state.externalVariables.compactMap {
            guard let signal = externalVariables[$0] else {
                fatalError("External variable \($0) not found for state \(state.name)")
            }
            guard signal.mode != .input else {
                return nil
            }
            return signal.type.signalType.encodedBits
        }
        let writeExternalSize = writeExternals.reduce(0, +)
        let writeSnapshotSize = writeExternalSize + stateSize + machineVariablesSize + 1 + stateSize
        let totalSize = readSnapshotSize + writeSnapshotSize
        let numberOfAddresses = totalSize / 31 + 1
        self.init(cTypeName: "\(name)_STATE_\(state.name.rawValue)_Raw", numberOfAddresses: numberOfAddresses)
    }

    init(cTypeName name: String, numberOfAddresses: Int) {
        let dataVariables = (0..<numberOfAddresses).map { "uint32_t data\($0);" }.joined(separator: "\n")
        self = """
        typedef struct \(name) {
        \(dataVariables.indent(amount: 1))
        } \(name)_t;
        """
    }

}
