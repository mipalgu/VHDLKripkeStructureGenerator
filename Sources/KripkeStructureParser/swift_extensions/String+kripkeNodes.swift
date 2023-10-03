// String+kripkeNodes.swift
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

extension String {

    // swiftlint:disable line_length

    init<T>(readStateFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let name = state.name.rawValue + "Read"
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let definitions = readSnapshot.types.map {
            "public var \($0.name.rawValue): \($0.type.signalType.swiftLiteral)"
        }
        .joined(separator: "\n\n")
        let initParameters = readSnapshot.types.map {
            "\($0.name.rawValue): \($0.type.signalType.swiftLiteral)"
        }
        .joined(separator: ", ")
        let initAssignments = readSnapshot.types.map {
            "self.\($0.name.rawValue) = \($0.name.rawValue)"
        }
        .joined(separator: "\n")
        let encodedPreamble = readSnapshot.types.map {
            let functionName = String(
                stateVariableAccessNameFor: state,
                in: representation,
                variable: NodeVariable(data: $0, type: .read)
            )
            return "let \($0.name.rawValue)Value = \(functionName)(value)"
        }
        .joined(separator: "\n")
        let encodedAssignments = readSnapshot.types.map {
            let signalType = $0.type.signalType
            return "\($0.name.rawValue): \(signalType.swiftLiteral)(value: " +
                "\($0.name.rawValue)Value, numberOfBits: \(signalType.encodedBits))!"
        }
        .joined(separator: ", ")
        let machineName = representation.machine.name.rawValue
        self = """
        import C\(machineName)
        import VHDLParsing

        public struct \(name): Equatable, Hashable, Codable, Sendable {
        \(definitions.indent(amount: 1))
            public init(\(initParameters)) {
        \(initAssignments.indent(amount: 2))
            }

            public init?(value: UInt32) {
                guard \(machineName)_isValid(value), \(machineName)_\(state.name.rawValue)_isValid(value) else {
                    return nil
                }
        \(encodedPreamble.indent(amount: 2))
                self.init(\(encodedAssignments))
            }
        }
        """
    }

    init<T>(writeStateFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let name = state.name.rawValue + "Write"
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let definitions = writeSnapshot.types.map {
            "public var \($0.name.rawValue): \($0.type.signalType.swiftLiteral)"
        }
        .joined(separator: "\n\n")
        let initParameters = writeSnapshot.types.map {
            "\($0.name.rawValue): \($0.type.signalType.swiftLiteral)"
        }
        .joined(separator: ", ")
        let initAssignments = writeSnapshot.types.map {
            "self.\($0.name.rawValue) = \($0.name.rawValue)"
        }
        .joined(separator: "\n")
        let encodedPreamble = writeSnapshot.types.map {
            let functionName = String(
                stateVariableAccessNameFor: state,
                in: representation,
                variable: NodeVariable(data: $0, type: .read)
            )
            return "let \($0.name.rawValue)Value = \(functionName)(value)"
        }
        .joined(separator: "\n")
        let encodedAssignments = writeSnapshot.types.map {
            let signalType = $0.type.signalType
            guard $0.name != .nextState else {
                return "\($0.name.rawValue): LogicVector(values: BitVector(value: " +
                "\($0.name.rawValue)Value, numberOfBits: \(signalType.bits))!.values.map { " +
                "LogicLiteral(bit: $0) })"
            }
            return "\($0.name.rawValue): \(signalType.swiftLiteral)(value: " +
                "\($0.name.rawValue)Value, numberOfBits: \(signalType.encodedBits))!"
        }
        .joined(separator: ", ")
        let machineName = representation.machine.name.rawValue
        self = """
        import C\(machineName)
        import VHDLParsing

        public struct \(name): Equatable, Hashable, Codable, Sendable {
        \(definitions.indent(amount: 1))
            public init(\(initParameters)) {
        \(initAssignments.indent(amount: 2))
            }

            public init?(value: UInt32) {
                guard \(machineName)_isValid(value), \(machineName)_\(state.name.rawValue)_isValid(value) else {
                    return nil
                }
        \(encodedPreamble.indent(amount: 2))
                self.init(\(encodedAssignments))
            }
        }
        """
    }

    init<T>(kripkeNodeFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let machineName = representation.machine.name.rawValue
        self = """
        import C\(machineName)
        import VHDLParsing

        public struct \(state.name.rawValue)Ringlet: Equatable, Hashable, Codable, Sendable {

            public var read: \(state.name.rawValue)Read

            public var write: \(state.name.rawValue)Write

            public init(read: \(state.name.rawValue)Read, write: \(state.name.rawValue)Write) {
                self.read = read
                self.write = write
            }

            public init?(value: UInt32) {
                guard let read = \(state.name.rawValue)Read(value: value), let write = \(state.name.rawValue)Write(value: value) else {
                    return nil
                }
                self.init(read: read, write: write)
            }

        }
        """
    }

    // swiftlint:enable line_length

}

extension SignalType {

    var swiftLiteral: String {
        switch self {
        case .bit:
            return "BitLiteral"
        case .boolean:
            return "Bool"
        case .integer:
            return "Int"
        case .natural, .positive:
            return "UInt"
        case .stdLogic, .stdULogic:
            return "LogicLiteral"
        case .ranged(let type):
            return type.swiftLiteral
        case .real:
            fatalError("Not supported!")
        }
    }

}

extension RangedType {

    var swiftLiteral: String {
        switch self {
        case .bitVector, .signed, .unsigned:
            return "BitVector"
        case .integer:
            return "Int"
        case .stdLogicVector, .stdULogicVector:
            return "LogicVector"
        }
    }

}
