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

import StringHelpers
import Utilities
import VHDLMachines
import VHDLParsing

/// Add inits for Kripke node creation.
extension String {

    // swiftlint:disable line_length

    /// Create the `Swift` code that defines the `Read` Kripke state for the given state in the machine.
    /// - Parameters:
    ///   - state: The `State` to create the read state for.
    ///   - representation: The machine representation that contains the `state`.
    init<T>(readStateFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let name = state.name.rawValue + "Read"
        let readSnapshot = Record(readSnapshotFor: state, in: representation)
        let definitions = readSnapshot.definitions.map { $0.indent(amount: 1) }.joined(separator: "\n\n")
        let initParameters = readSnapshot.initParameters.joined(separator: ", ")
        let initAssignments = readSnapshot.initAssignments.joined(separator: "\n")
        let encodedPreamble = readSnapshot.valueAssignment(
            state: state, representation: representation, type: .read
        )
        .joined(separator: "\n")
        let encodedAssignments = readSnapshot.encodedAssignments.joined(separator: ",\n")
        let parameters = readSnapshot.literalAssignments.joined(separator: ",\n")
        let machineName = representation.entity.name.rawValue
        let properties = String(readPropertiesFor: representation, state: state)
        self = """
        import C\(machineName)
        import VHDLParsing

        public struct \(name): Equatable, Hashable, Codable, Sendable {

        \(definitions)

        \(properties.indent(amount: 1))

            public init(\(initParameters)) {
        \(initAssignments.indent(amount: 2))
            }

            public init?(value: UInt32) {
                guard \(machineName)_isValid(value), \(machineName)_\(state.name.rawValue)_isValid(value) else {
                    return nil
                }
        \(encodedPreamble.indent(amount: 2))
                guard
        \(encodedAssignments.indent(amount: 3))
                else {
                    return nil
                }
                self.init(
        \(parameters.indent(amount: 3))
                )
            }

        }

        """
    }

    /// Create the `Swift` code that defines the `Write` Kripke state for the given state in the machine.
    /// - Parameters:
    ///   - state: The `State` to create the write state for.
    ///   - representation: The machine representation that contains the `state`.
    init<T>(writeStateFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let name = state.name.rawValue + "Write"
        // swiftlint:disable:next force_unwrapping
        let writeSnapshot = Record(writeSnapshotFor: state, in: representation)!
        let definitions = writeSnapshot.definitions.map { $0.indent(amount: 1) }.joined(separator: "\n\n")
        let initParameters = writeSnapshot.initParameters.joined(separator: ", ")
        let initAssignments = writeSnapshot.initAssignments.joined(separator: "\n")
        let encodedPreamble = writeSnapshot.valueAssignment(
            state: state,
            representation: representation,
            type: .write,
            count: Record(readSnapshotFor: state, in: representation).bits
        )
        .joined(separator: "\n")
        let encodedAssignments = writeSnapshot.types.map {
            let signalType = $0.type.signalType
            guard $0.name != .nextState else {
                return "let \(VariableName.nextState.rawValue)BitVector = BitVector(value: " +
                    "\($0.name.rawValue)Value, numberOfBits: \(signalType.bits))"
            }
            return "let \($0.name.rawValue)Literal = \(signalType.swiftLiteral)(value: " +
                    "\($0.name.rawValue)Value, numberOfBits: \(signalType.encodedBits))"
        }
        let machineName = representation.entity.name.rawValue
        let parameters = writeSnapshot.literalAssignments.joined(separator: ",\n")
        let properties = String(writePropertiesFor: representation, state: state)
        self = """
        import C\(machineName)
        import VHDLParsing

        public struct \(name): Equatable, Hashable, Codable, Sendable {

        \(definitions)

        \(properties.indent(amount: 1))

            public init(\(initParameters)) {
        \(initAssignments.indent(amount: 2))
            }

            public init?(value: UInt32) {
                guard \(machineName)_isValid(value), \(machineName)_\(state.name.rawValue)_isValid(value) else {
                    return nil
                }
        \(encodedPreamble.indent(amount: 2))
        \(String(guardedStatements: encodedAssignments).indent(amount: 2))
                let nextStateLiteral = LogicVector(
                    values: nextStateBitVector.values.map { LogicLiteral(bit: $0) }
                )
                self.init(
        \(parameters.indent(amount: 3))
                )
            }

        }

        """
    }

    /// Create a guard around a set of statements.
    /// - Parameter statements: The statements to place within the guard.
    @inlinable
    init(guardedStatements statements: [String]) {
        self = """
        guard
        \(statements.map { $0.indent(amount: 1) }.joined(separator: ",\n"))
        else {
            return nil
        }
        """
    }

    /// Create the ringlet definition in the Kripke structure.
    /// - Parameters:
    ///   - state: The state to create the ringlet for.
    ///   - representation: The machine representation that contains the `state`.
    @inlinable
    init<T>(kripkeNodeFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let machineName = representation.entity.name.rawValue
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
                guard
                    let read = \(state.name.rawValue)Read(value: value),
                    let write = \(state.name.rawValue)Write(value: value)
                else {
                    return nil
                }
                self.init(read: read, write: write)
            }

        }

        """
    }

    // swiftlint:enable line_length

    init<T>(readPropertiesFor representation: T, state: State) where T: MachineVHDLRepresentable {
        let name = representation.entity.name
        let machine = representation.machine
        let readExternalVariables = machine.externalSignals.filter {
            state.externalVariables.contains($0.name) && $0.mode != .output
        }
        let readAssignments = readExternalVariables.flatMap {
            let snapshotName = "\(name.rawValue)_\($0.name.rawValue)"
            return [
                ".\(snapshotName): \(String(literalType: $0.type.signalType, value: $0.name.rawValue))",
                ".\($0.name.rawValue): \(String(literalType: $0.type.signalType, value: $0.name.rawValue))"
            ]
        }
        let writeExternals = machine.externalSignals.filter {
            $0.mode == .output || (
                !state.externalVariables.contains($0.name) && $0.mode != .output && $0.mode != .input
            )
        }
        let writeAssignments = writeExternals.map {
            let snapshotName = "\(name.rawValue)_\($0.name.rawValue)"
            return ".\(snapshotName): \(String(literalType: $0.type.signalType, value: snapshotName))"
        }
        let machineAssignments = machine.machineSignals.map {
            let snapshotName = "\(name.rawValue)_\($0.name.rawValue)"
            return ".\(snapshotName): \(String(literalType: $0.type.signalType, value: snapshotName))"
        }
        let stateAssignments = state.signals.map {
            let snapshotName = "\(name.rawValue)_STATE_\(state.name.rawValue)_\($0.name.rawValue)"
            return ".\(snapshotName): \(String(literalType: $0.type.signalType, value: snapshotName))"
        }
        let assignments = readAssignments + writeAssignments + machineAssignments + stateAssignments
        guard !assignments.isEmpty else {
            self = "var properties: [VariableName: SignalLiteral] { [:] }"
            return
        }
        self = """
        var properties: [VariableName: SignalLiteral] {
            [
        \(assignments.joined(separator: ",\n").indent(amount: 2))
            ]
        }
        """
    }

    init<T>(writePropertiesFor representation: T, state: State) where T: MachineVHDLRepresentable {
        let name = representation.entity.name
        let machine = representation.machine
        let writeExternals = machine.externalSignals.filter {
            state.externalVariables.contains($0.name) && $0.mode != .input
        }
        let writeAssignments = writeExternals.flatMap {
            let snapshotName = "\(name.rawValue)_\($0.name.rawValue)"
            return [
                ".\(snapshotName): \(String(literalType: $0.type.signalType, value: $0.name.rawValue))",
                ".\($0.name.rawValue): \(String(literalType: $0.type.signalType, value: $0.name.rawValue))"
            ]
        }
        let machineAssignments = machine.machineSignals.map {
            let snapshotName = "\(name.rawValue)_\($0.name.rawValue)"
            return ".\(snapshotName): \(String(literalType: $0.type.signalType, value: snapshotName))"
        }
        let stateAssignments = state.signals.map {
            let snapshotName = "\(name.rawValue)_STATE_\(state.name.rawValue)_\($0.name.rawValue)"
            return ".\(snapshotName): \(String(literalType: $0.type.signalType, value: snapshotName))"
        }
        let assignments = writeAssignments + machineAssignments + stateAssignments
        guard !assignments.isEmpty else {
            self = "var properties: [VariableName: SignalLiteral] { [:] }"
            return
        }
        self = """
        var properties: [VariableName: SignalLiteral] {
            [
        \(assignments.joined(separator: ",\n").indent(amount: 2))
            ]
        }
        """
    }

    init(literalType: SignalType, value: String) {
        switch literalType {
        case .bit:
            self = ".bit(value: \(value))"
        case .boolean:
            self = ".boolean(value: \(value))"
        case .integer, .natural, .positive:
            self = ".integer(value: \(value))"
        case .stdLogic, .stdULogic:
            self = ".logic(value: \(value))"
        case .real:
            self = ".decimal(value: \(value))"
        case .ranged(let type):
            switch type {
            case .bitVector, .signed, .unsigned:
                self = ".vector(value: .bits(value: \(value)))"
            case .integer:
                self = ".integer(value: \(value))"
            case .stdLogicVector, .stdULogicVector:
                self = ".vector(value: .logics(value: \(value)))"
            }
        }
    }

}

/// Add `swiftLiteral`.
extension SignalType {

    /// The equivalent `Swift` type for storing the literal value.
    @inlinable var swiftLiteral: String {
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

/// Add `swiftLiteral`.
extension RangedType {

    /// The equivalent `Swift` type for storing the literal value.
    @inlinable var swiftLiteral: String {
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

/// Add record helper properties for kripke node creation.
extension Record {

    /// The definition of the types within a kripke node.
    @inlinable var definitions: [String] {
        self.types.map { "public var \($0.name.rawValue): \($0.type.signalType.swiftLiteral)" }
    }

    /// The assignment of the literal values of each type within a kripke node.
    @inlinable var encodedAssignments: [String] {
        self.types.map {
            let signalType = $0.type.signalType
            return "let \($0.name.rawValue)Literal = \(signalType.swiftLiteral)(value: " +
                "\($0.name.rawValue)Value, numberOfBits: \(signalType.encodedBits))"
        }
    }

    /// The assignment of the properties within a kripke node.
    @inlinable var initAssignments: [String] {
        self.types.map { "self.\($0.name.rawValue) = \($0.name.rawValue)" }
    }

    /// The parameters into the kripke node initializer.
    @inlinable var initParameters: [String] {
        self.types.map { "\($0.name.rawValue): \($0.type.signalType.swiftLiteral)" }
    }

    /// The literal assignments for the kripke node.
    @inlinable var literalAssignments: [String] {
        self.types.map { "\($0.name.rawValue): \($0.name.rawValue)Literal" }
    }

    /// Create the swift code that defines the values of each record type within a kripke node.
    /// - Parameters:
    ///   - state: The state this record represents.
    ///   - representation: The machine containing the state.
    ///   - type: The type of the kripke node to create.
    /// - Returns: The code that creates the values of each record type.
    func valueAssignment<T>(
        state: State, representation: T, type: NodeType, count: Int = 0
    ) -> [String] where T: MachineVHDLRepresentable {
        guard state.numberOfAddressesForRinglet(in: representation) > 1 else {
            return self.types.map {
                let functionName = String(
                    stateVariableAccessNameFor: state,
                    in: representation,
                    variable: NodeVariable(data: $0, type: type)
                )
                return "let \($0.name.rawValue)Value = \(functionName)(value)"
            }
        }
        return self.encodedIndexes(ignoring: [.nextState])
            .map { IndexedType(record: $0, index: $1.mutateIndexes { $0 + count }) }
            .map {
                let functionName = String(
                    stateVariableAccessNameFor: state,
                    in: representation,
                    variable: NodeVariable(data: $0.record, type: type)
                )
                let valueName = "\($0.record.name.rawValue)Value"
                guard $0.index.isAccrossBoundary(state: state, in: representation) else {
                    return "let \(valueName) = \(functionName)(value)"
                }
                let access = MemoryAccess.getAccess(indexes: $0.index, in: representation)
                let tupleTypes = [String](repeating: "UInt32", count: access.count).joined(separator: ", ")
                let initialValues = [String](repeating: "0", count: access.count).joined(separator: ", ")
                return """
                var \(valueName): (\(tupleTypes)) = (\(initialValues))
                withUnsafeMutablePointer(to: &\(valueName)) {
                    \(functionName)(value, $0)
                }
                """
            }
    }

}
