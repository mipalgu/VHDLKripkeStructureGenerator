// VariableParser.swift
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

import Foundation
import Utilities
import VHDLMachines
import VHDLParsing

struct VariableParser {

    let definitions: [NodeVariable: String]

    let functions: [NodeVariable: String]

    init<T>(state: State, in representation: T) where T: MachineVHDLRepresentable {
        let read = Record(readSnapshotFor: state, in: representation)
        let readIndexes = read.encodedIndexes
        let numberOfBits = read.encodedBits
        let write = Record(writeSnapshotFor: state, in: representation)!
        let writeIndexes = write.encodedIndexes(ignoring: [.nextState], offset: numberOfBits)
        let functions = readIndexes.map {
            let variable = NodeVariable(data: $0, type: .read)
            let functionBody = String(
                stateVariableAccessFor: state, in: representation, index: $1, variable: variable
            )
            return (variable, functionBody)
        } + writeIndexes.map {
            let variable = NodeVariable(data: $0, type: .write)
            let functionBody = String(
                stateVariableAccessFor: state, in: representation, index: $1, variable: variable
            )
            return (variable, functionBody)
        }
        let definitions = readIndexes.map {
            let variable = NodeVariable(data: $0.0, type: .read)
            let definition = String(
                stateVariableAccessDefinitionsFor: state, in: representation, variable: variable
            )
            return (variable, definition)
        } + writeIndexes.map {
            let variable = NodeVariable(data: $0.0, type: .write)
            let definition = String(
                stateVariableAccessDefinitionsFor: state, in: representation, variable: variable
            )
            return (variable, definition)
        }
        self.init(
            definitions: Dictionary(uniqueKeysWithValues: definitions),
            functions: Dictionary(uniqueKeysWithValues: functions)
        )
    }

    init(definitions: [NodeVariable: String], functions: [NodeVariable: String]) {
        self.definitions = definitions
        self.functions = functions
    }

}

extension SignalType {

    var ctype: (CType, Int) {
        switch self {
        case .bit, .stdLogic, .stdULogic:
            return (.uint8, 1)
        case .boolean:
            return (.bool, 1)
        case .integer:
            return (.int32, 1)
        case .natural, .positive:
            return (.uint32, 1)
        case .real:
            return (.float, 1)
        case .ranged(let type):
            return type.ctype
        }
    }

}

extension RangedType {

    var ctype: (CType, Int) {
        switch self {
        case .bitVector, .stdLogicVector, .stdULogicVector, .unsigned:
            return self.encodedBits.bitsToCType
        case .integer(let size):
            let bits = self.encodedBits
            let ctype = bits.bitsToCType
            guard case .literal(let literal) = size.min, case .integer(let min) = literal, min > 0 else {
                return (CType(signedVersion: ctype.0), ctype.1)
            }
            return ctype
        case .signed:
            let ctype = bits.bitsToCType
            return (CType(signedVersion: ctype.0), ctype.1)
        }
    }

}

extension Int {

    var bitsToCType: (CType, Int) {
        let size = self
        let base = size / 8
        let remainder = size - base * 8
        guard remainder > 0 else {
            return (.uint8, 1)
        }
        let base16 = size / 16
        let remainder16 = size - base16 * 16
        guard remainder16 > 0 else {
            return (.uint16, 1)
        }
        let base32 = size / 32
        let remainder32 = size - base32 * 32
        guard remainder32 > 0 else {
            return (.uint32, 1)
        }
        return (.uint32, base32 + 1)
    }

}

extension String {

    init<T>(
        stateVariableAccessFor state: State,
        in representation: T,
        index: VectorIndex,
        variable: NodeVariable
    ) where T: MachineVHDLRepresentable {
        let functionName = String(
            stateVariableAccessNameFor: state, in: representation, variable: variable
        )
        let parameters = String(stateVariableAccessParametersFor: state, in: representation)
        let returnTypeTuple = variable.data.type.signalType.ctype
        let returnType = returnTypeTuple.1 > 1 ? "\(returnTypeTuple.0)*" : returnTypeTuple.0.rawValue
        let body = String(
            stateVariableAccessBodyFor: state, in: representation, index: index, variable: variable
        )
        self = """
        \(returnType) \(functionName)(\(parameters))
        {
        \(body.indent(amount: 1))
        }
        """
    }

    init<T>(
        stateVariableAccessDefinitionsFor state: State,
        in representation: T,
        variable: NodeVariable
    ) where T: MachineVHDLRepresentable {
        let functionName = String(
            stateVariableAccessNameFor: state, in: representation, variable: variable
        )
        let parameters = String(stateVariableAccessParametersFor: state, in: representation)
        let returnTypeTuple = variable.data.type.signalType.ctype
        let returnType = returnTypeTuple.1 > 1 ? "\(returnTypeTuple.0)*" : returnTypeTuple.0.rawValue
        self = "\(returnType) \(functionName)(\(parameters));"
    }

    init<T>(
        stateVariableAccessBodyFor state: State,
        in representation: T,
        index: VectorIndex,
        variable: NodeVariable
    ) where T: MachineVHDLRepresentable {
        guard case .range(let size) = index else {
            guard case .index(let expression) = index else {
                fatalError("Invalid index")
            }
            let size = VectorSize.to(lower: expression, upper: expression)
            let mask = String(maskFor: size, arraySize: 1)
            let shiftAmount = 32 - 1 - size.max.integer
            let ctype = variable.data.type.signalType.ctype
            let operation = "(data & 0b\(mask)) >> \(shiftAmount)"
            self = "return (\(ctype.0.rawValue))(\(operation));"
            return
        }
        let mask = String(maskFor: size, arraySize: 1)
        let shiftAmount = 32 - 1 - size.max.integer
        let ctype = variable.data.type.signalType.ctype
        let operation = "(data & 0b\(mask)) >> \(shiftAmount)"
        self = "return (\(ctype.0.rawValue))(\(operation));"
    }

    init<T>(
        stateVariableAccessNameFor state: State, in representation: T, variable: NodeVariable
    ) where T: MachineVHDLRepresentable {
        self = "\(representation.entity.name.rawValue)_\(state.name.rawValue)_\(variable.type.rawValue)" +
            "_\(variable.data.name.rawValue)"
    }

    init<T>(
        stateVariableAccessParametersFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        let numberOfAddresses = state.numberOfAddressesForRinglet(in: representation)
        guard numberOfAddresses == 1 else {
            fatalError("Not supported!")
            // self = "uint32_t *data"
            // return
        }
        self = "uint32_t data"
    }

    init(maskFor size: VectorSize, arraySize: Int) {
        guard arraySize == 1 else {
            fatalError("Not supported!")
        }
        let oneBits = Set(size.min.integer...size.max.integer)
        self = (0..<32).map { oneBits.contains($0) ? "1" : "0" }.joined()
    }

}

extension State {

    func numberOfAddressesForRinglet<T>(in representation: T) -> Int where T: MachineVHDLRepresentable {
        let size = self.encodedSize(in: representation)
        let dataSize = 32 - representation.numberOfStateBits! - 1
        return Int(ceil(Double(size) / Double(dataSize)))
    }

}

extension Expression {

    var integer: Int {
        guard case .literal(let literal) = self, case .integer(let value) = literal else {
            fatalError("Invalid expression.")
        }
        return value
    }

}
