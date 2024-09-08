// String+VHDLKripkeStructure.swift
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
import Utilities

extension String {

    static let readNode = """
    protocol ReadNode {

        var executeOnEntry: Bool { get }

        var currentState: VariableName { get }

        var properties: [VariableName: SignalLiteral] { get }

        var externals: Set<VariableName> { get }

    }
    """

    static let writeNode = """
    protocol WriteNode {

        var executeOnEntry: Bool { get }

        var currentState: VariableName { get }

        var properties: [VariableName: SignalLiteral] { get }

        var externals: Set<VariableName> { get }

        var nextStateName: VariableName { get }

    }
    """

    static let ringlet = """
    protocol Ringlet {

        var readNode: any ReadNode { get }

        var writeNode: any WriteNode { get }

    }
    """

    static let nodePropertyInit = """
    extension Node {

        convenience init(
            properties: [VariableName: SignalLiteral],
            previousProperties: [VariableName: SignalLiteral],
            type: NodeType,
            currentState: VariableName,
            executeOnEntry: Bool,
            nextState: VariableName
        ) {
            var newProperties = previousProperties
            properties.forEach { newProperties[$0] = $1 }
            self.init(
                type: type,
                currentState: currentState,
                executeOnEntry: executeOnEntry,
                nextState: nextState,
                properties: newProperties
            )
        }

    }
    """

    static let typeExtensions = """
    extension SignalType {

        var allValues: [SignalLiteral] {
            switch self {
            case .bit:
                return [.bit(value: .low), .bit(value: .high)]
            case .boolean:
                return [.boolean(value: false), .boolean(value: true)]
            case .stdLogic, .stdULogic:
                return [.logic(value: .low), .logic(value: .high), .logic(value: .highImpedance)]
            case .integer:
                return (Int32.min...Int32.max).map { .integer(value: Int($0)) }
            case .natural:
                return (0...Int32.max).map { .integer(value: Int($0)) }
            case .positive:
                return (1...Int32.max).map { .integer(value: Int($0)) }
            case .real:
                fatalError("Not supported!")
            case .ranged(let type):
                return type.allValues
            }
        }

    }

    extension RangedType {

        var allValues: [SignalLiteral] {
            let values: [[SignalLiteral]]
            switch self {
            case .bitVector(let size), .signed(let size), .unsigned(let size):
                values = (0..<size.size!).map { _ in SignalType.bit.allValues}
            case .integer:
                fatalError("Not supported")
            case .stdLogicVector(let size), .stdULogicVector(let size):
                values = (0..<size.size!).map { _ in SignalType.stdLogic.allValues}
            }
            var indexes = Array(repeating: 0, count: values.count)
            var allValues: [SignalLiteral] = []
            let maxIndex = values[0].count - 1
            while true {
                let combination = indexes.enumerated().map { values[$0][$1] }
                switch self {
                case .bitVector, .signed, .unsigned:
                    allValues.append(SignalLiteral.vector(value: .bits(
                        value: BitVector(values: combination.map { $0.asBit })
                    )))
                case .stdLogicVector, .stdULogicVector:
                    allValues.append(SignalLiteral.vector(value: .logics(
                        value: LogicVector(values: combination.map { $0.asLogic })
                    )))
                default:
                    fatalError()
                }
                guard let mutatingIndex = indexes.firstIndex(where: { $0 < maxIndex }) else {
                    return allValues
                }
                indexes[mutatingIndex] += 1
            }
        }

    }

    extension SignalLiteral {

        var asBit: BitLiteral {
            guard case .bit(let value) = self else {
                fatalError()
            }
            return value
        }

        var asLogic: LogicLiteral {
            guard case .logic(let value) = self else {
                fatalError()
            }
            return value
        }

    }
    """

    init<T>(vhdlKripkeStructureFor representation: T) where T: MachineVHDLRepresentable {
        let includes = """
        import VHDLKripkeStructures
        import VHDLParsing
        """
        let readExtensions = representation.machine.states.map {
            String(readNodeConformanceFor: $0, in: representation)
        }
        .joined(separator: "\n\n")
        let writeExtensions = representation.machine.states.map {
            String(writeNodeConformanceFor: $0, in: representation)
        }
        .joined(separator: "\n\n")
        let ringletExtensions = representation.machine.states.map {
            String(ringletConformanceFor: $0)
        }
        .joined(separator: "\n\n")
        let kripkeExtensions = String(kripkeStructureExtensionFor: representation)
        let dictionaryExtensions = String(dictionaryPropertiesFor: representation)
        let nameExtension = String(nameExtensionFor: representation)
        self = """
        \(includes)

        \(String.readNode)

        \(String.writeNode)

        \(String.ringlet)

        \(readExtensions)

        \(writeExtensions)

        \(ringletExtensions)

        \(kripkeExtensions)

        \(String.nodePropertyInit)

        \(dictionaryExtensions)

        \(nameExtension)

        \(String.typeExtensions)

        """
    }

    init<T>(readNodeConformanceFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let externals = state.externalVariables.filter { name in
            guard let signal = representation.machine.externalSignals.first(where: { $0.name == name }) else {
                return false
            }
            return signal.mode != .output
        }
        .map { ".\($0.rawValue)" }
        .joined(separator: ", ")
        self = """
        extension \(state.name.rawValue)Read: ReadNode {

            var currentState: VariableName { .\(state.name.rawValue) }

            var externals: Set<VariableName> { [\(externals)] }

        }
        """
    }

    init<T>(writeNodeConformanceFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let externals = state.externalVariables.filter { name in
            guard let signal = representation.machine.externalSignals.first(where: { $0.name == name }) else {
                return false
            }
            return signal.mode != .input
        }
        .map { ".\($0.rawValue)" }
        .joined(separator: ", ")
        self = """
        extension \(state.name.rawValue)Write: WriteNode {

            var currentState: VariableName { .\(state.name.rawValue) }

            var nextStateName: VariableName { VariableName(state: self.nextState)! }

            var externals: Set<VariableName> { [\(externals)] }

        }
        """
    }

    init(ringletConformanceFor state: State) {
        self = """
        extension \(state.name.rawValue)Ringlet: Ringlet {

            var readNode: any ReadNode { self.read }

            var writeNode: any WriteNode { self.write }

        }
        """
    }

    init<T>(dictionaryPropertiesFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let externals = machine.externalSignals.map {
            guard let defaultValue = $0.defaultValue, case .literal(let literal) = defaultValue else {
                return (
                    "\($0.name.rawValue)",
                    $0.type.signalType.defaultValueCreation
                )
            }
            return (
                "\($0.name.rawValue)",
                literal.defaultValueCreation
            )
        }
        let snapshots = externals.map {
            ("\(representation.entity.name.rawValue)_\($0.0)", $0.1)
        }
        let machineSignals = machine.machineSignals.map {
            guard let defaultValue = $0.defaultValue, case .literal(let literal) = defaultValue else {
                return (
                    "\(representation.entity.name.rawValue)_\($0.name.rawValue)",
                    $0.type.signalType.defaultValueCreation
                )
            }
            return (
                "\(representation.entity.name.rawValue)_\($0.name.rawValue)",
                literal.defaultValueCreation
            )
        }
        let stateSignals = machine.states.flatMap { state in
            state.signals.map {
                let name = "\(representation.entity.name.rawValue)_STATE_\(state.name.rawValue)_" +
                    "\($0.name.rawValue)"
                guard let defaultValue = $0.defaultValue, case .literal(let literal) = defaultValue else {
                return (
                    name,
                    $0.type.signalType.defaultValueCreation
                )
            }
            return (
                name,
                literal.defaultValueCreation
            )
            }
        }
        let allSignals = externals + snapshots + machineSignals + stateSignals
        let assignments = allSignals.map { "VariableName(rawValue: \"\($0.0)\")!: \($0.1)" }
        let internalSignals = snapshots + machineSignals + stateSignals
        let internalDefinitions = internalSignals.map { "VariableName(rawValue: \"\($0.0)\")!" }
        self = """
        extension Dictionary where Key == VariableName, Value == SignalLiteral {

            static let defaultProperties: [VariableName: SignalLiteral] = [
        \(assignments.joined(separator: ",\n").indent(amount: 2))
            ]

            static let internalVariables: [VariableName] = [
        \(internalDefinitions.joined(separator: ",\n").indent(amount: 2))
            ]

            static var cache: [Set<VariableName>: [[VariableName: SignalLiteral]]] = [:]

            static func allReadExternalValues(excluding: Set<VariableName>) -> [[VariableName: SignalLiteral]] {
                if let cached = cache[excluding] {
                    return cached
                }
                let validExternals = VariableName.readExternals.filter { !excluding.contains($0.key) }
                let validValues: [VariableName: [SignalLiteral]] = Dictionary<VariableName, [SignalLiteral]>(uniqueKeysWithValues: validExternals.map {
                    ($0.key, $0.value.allValues)
                })
                var allConfigurations: [[VariableName: SignalLiteral]] = []
                var indexes = [VariableName: Int](uniqueKeysWithValues: validValues.map { ($0.key, 0) })
                let maxIndexes = [VariableName: Int](uniqueKeysWithValues: validValues.map { ($0.key, $0.value.count - 1) })
                while true {
                    let configuration = [VariableName: SignalLiteral](uniqueKeysWithValues: indexes.flatMap {
                        [
                            ($0.key, validValues[$0.key]![$0.value]),
                            (VariableName(rawValue: "\(representation.entity.name.rawValue)_\\($0.key.rawValue)")!, validValues[$0.key]![$0.value])
                        ]
                    })
                    allConfigurations.append(configuration)
                    guard let mutatingIndex = indexes.first(where: { $0.value < maxIndexes[$0.key]! })?.key else {
                        cache[excluding] = allConfigurations
                        return allConfigurations
                    }
                    indexes[mutatingIndex]! += 1
                }
            }

        }
        """
    }

    init<T>(nameExtensionFor representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let stateDefinitions = machine.states.map {
            "static let \($0.name.rawValue) = VariableName(rawValue: \"\($0.name.rawValue)\")!"
        }
        let externalDefinitions = machine.externalSignals.flatMap {
            [
                "static let \($0.name.rawValue) = VariableName(rawValue: \"\($0.name.rawValue)\")!",
                "static let \(representation.entity.name)_\($0.name.rawValue) = " +
                    "VariableName(rawValue: \"\(representation.entity.name)_\($0.name.rawValue)\")!"
            ]
        }
        let machineDefinitions = machine.machineSignals.map {
            "static let \(representation.entity.name)_\($0.name.rawValue) = " +
                    "VariableName(rawValue: \"\(representation.entity.name)_\($0.name.rawValue)\")!"
        }
        let stateSignalDefinitions = machine.states.flatMap { state in
            state.signals.map {
                "static let \(representation.entity.name)_STATE_\(state.name.rawValue)_\($0.name.rawValue)" +
                    " = VariableName(rawValue: \"\(representation.entity.name)_STATE_\(state.name.rawValue)" +
                    "_\($0.name.rawValue)\")!"
            }
        }
        let vectorCases = machine.states.map {
            let instantiation = $0.representation(in: representation)
            return """
            case LogicVector(rawValue: \"\"\"
            \(instantiation.rawValue)
            \"\"\")!.values:
                self = .\($0.name.rawValue)
            """
        }
        let allReadExternals = machine.externalSignals.filter { $0.mode != .output }
        let readExternals = allReadExternals.map {
            "\($0.name.rawValue): SignalType(rawValue: \"\($0.type.rawValue)\")!"
        }
        .joined(separator: ", ")
        let stateReadExternals = machine.states.map {
            let externals = $0.externalVariables.filter { allReadExternals.map(\.name).contains($0) }
                .map(\.rawValue)
                .joined(separator: ", ")
            return """
            case .\($0.name.rawValue):
                return [\(externals)]
            """
        }
        .joined(separator: "\n")
        .indent(amount: 2)
        self = """
        extension VariableName {

        \(stateDefinitions.joined(separator: "\n").indent(amount: 1))

        \(externalDefinitions.joined(separator: "\n").indent(amount: 1))

        \(machineDefinitions.joined(separator: "\n").indent(amount: 1))

        \(stateSignalDefinitions.joined(separator: "\n").indent(amount: 1))

            static let readExternals: [VariableName: SignalType] = [\(readExternals)]

            init?(state: LogicVector) {
                switch state.values {
        \(vectorCases.joined(separator: "\n").indent(amount: 2))
                default:
                    return nil
                }
            }

            static func readExternals(state: VariableName) -> Set<VariableName> {
                switch state {
        \(stateReadExternals)
                default:
                    fatalError()
                }
            }

        }
        """
    }

    init<T>(kripkeStructureExtensionFor representation: T) where T: MachineVHDLRepresentable {
        let initialState = representation.machine.states[representation.machine.initialState]
        let initialExternals = initialState.externalVariables.filter { name in
            guard let signal = representation.machine.externalSignals.first(where: { $0.name == name }) else {
                return false
            }
            return signal.mode != .output
        }
        let externalProperties = initialExternals.map {
            "$0 != .\($0.rawValue), $0 != VariableName(rawValue: \"\(representation.entity.name)_\($0.rawValue)\")!"
        }
        .joined(separator: ", ")
        let externalPropertiesGuard = """
        ringlet.read.properties.allSatisfy {
            guard \(externalProperties) else {
                return true
            }
            return [VariableName: SignalLiteral].defaultProperties[$0] == $1
        }
        """
        let stateRinglets = representation.machine.states.map {
            "structure.\($0.name.rawValue.lowercased())Ringlets"
        }
        .joined(separator: " + ")
        let clock = representation.machine.clocks[representation.machine.drivingClock]
        let (amount, exponent) = clock.periodTime!
        let costRW = "cost: Cost(time: ScientificQuantity(coefficient: \(amount * 4), " +
            "exponent: \(exponent)), energy: ScientificQuantity(coefficient: 0, exponent: 0))"
        let costWR = "cost: Cost(time: ScientificQuantity(coefficient: \(amount), " +
            "exponent: \(exponent)), energy: ScientificQuantity(coefficient: 0, exponent: 0))"
        self = """
        extension KripkeStructure {

            public convenience init(structure: \(representation.entity.name.rawValue)KripkeStructure) {
                let initialRinglets = structure.\(initialState.name.rawValue.lowercased())Ringlets.filter { ringlet in
                    ringlet.read.currentState == .\(initialState.name.rawValue) && ringlet.read.executeOnEntry
        \(initialExternals.isEmpty ? "" : "&& \(externalPropertiesGuard.indent(amount: 4))")
                }
                let initialNodes: Set<Node> = Set(initialRinglets.flatMap { ringlet in
                    [VariableName: SignalLiteral].allReadExternalValues(excluding: VariableName.readExternals(state: .Initial)).map {
                        Node(
                            type: .read,
                            currentState: ringlet.read.currentState,
                            executeOnEntry: ringlet.read.executeOnEntry,
                            nextState: ringlet.read.currentState,
                            properties: [VariableName: SignalLiteral].defaultProperties.merging($0) { $1 }.merging(ringlet.read.properties) { $1 }
                        )
                    }
                })
                var nodes: Set<Node> = initialNodes
                var edges: [Node: [Edge]] = [:]
                var pendingRinglets: [any Ringlet] = initialRinglets
                let allRinglets: [any Ringlet] = \(stateRinglets)
                repeat {
                    let ringlet = pendingRinglets.removeLast()
                    let readNodes: [Node] = nodes.filter { (node: Node) -> Bool in
                        node.executeOnEntry == ringlet.readNode.executeOnEntry
                            && node.currentState == ringlet.readNode.currentState
                            && node.type == .read
                            && ringlet.readNode.properties.allSatisfy { node.properties[$0] == $1 }
                    }
                    .flatMap { node in
                        [VariableName: SignalLiteral].allReadExternalValues(excluding: VariableName.readExternals(state: node.currentState)).map { value in
                            Node(
                                properties: value,
                                previousProperties: node.properties,
                                type: node.type,
                                currentState: node.currentState,
                                executeOnEntry: node.executeOnEntry,
                                nextState: node.nextState
                            )
                        }
                    }
                    let writeNodes = readNodes.map {
                        Node(
                            properties: ringlet.writeNode.properties,
                            previousProperties: $0.properties,
                            type: .write,
                            currentState: $0.currentState,
                            executeOnEntry: ringlet.writeNode.executeOnEntry,
                            nextState: ringlet.writeNode.nextStateName
                        )
                    }
                    writeNodes.enumerated().forEach {
                        let readNode = readNodes[$0]
                        let writeNode = $1
                        let edge: [Edge]
                        if let currentReadEdges = edges[readNode] {
                            edge = Array(Set(currentReadEdges).union(Set([Edge(target: writeNode, \(costRW))])))
                        } else {
                            edge = [Edge(target: writeNode, \(costRW))]
                        }
                        edges[readNode] = edge
                        guard !nodes.contains(writeNode) else {
                            return
                        }
                        nodes.insert(writeNode)
                        let newNodes = allRinglets.filter { ringlet in
                            writeNode.executeOnEntry == ringlet.readNode.executeOnEntry
                                && writeNode.nextState == ringlet.readNode.currentState
                                && [VariableName: SignalLiteral].internalVariables.allSatisfy {
                                    guard !$0.rawValue.hasPrefix("\(representation.entity.name.rawValue)_") else {
                                        let externalName = VariableName(
                                            rawValue: String($0.rawValue.dropFirst("\(representation.entity.name.rawValue)_".count))
                                        )!
                                        guard
                                            !ringlet.readNode.externals.contains(externalName),
                                            let value1 = ringlet.readNode.properties[$0],
                                            let value2 = writeNode.properties[$0]
                                        else {
                                            return true
                                        }
                                        return value1 == value2
                                    }
                                    guard
                                        !ringlet.readNode.externals.contains($0),
                                        let value1 = ringlet.readNode.properties[$0],
                                        let value2 = writeNode.properties[$0]
                                    else {
                                        return true
                                    }
                                    return value1 == value2
                                }
                        }
                        let nextNodes = newNodes.flatMap { ringlet in
                            [VariableName: SignalLiteral].allReadExternalValues(excluding:VariableName.readExternals(state: ringlet.readNode.currentState)).map {
                                Node(
                                    properties: $0.merging(ringlet.readNode.properties) { $1 },
                                    previousProperties: writeNode.properties,
                                    type: .read,
                                    currentState: ringlet.readNode.currentState,
                                    executeOnEntry: ringlet.readNode.executeOnEntry,
                                    nextState: ringlet.readNode.currentState
                                )
                            }
                        }
                        nextNodes.forEach { nodes.insert($0) }
                        let unseenRinglets = newNodes.filter {
                            let newWriteNode = Node(
                                properties: $0.writeNode.properties,
                                previousProperties: $0.readNode.properties,
                                type: .write,
                                currentState: $0.writeNode.currentState,
                                executeOnEntry: $0.writeNode.executeOnEntry,
                                nextState: $0.writeNode.nextStateName
                            )
                            return !nodes.contains(newWriteNode)
                        }
                        pendingRinglets += unseenRinglets
                        let newEdges = nextNodes.map {
                            Edge(target: $0, \(costWR))
                        }
                        if let currentEdges = edges[writeNode] {
                            edges[writeNode] = Array(Set(currentEdges).union(Set(newEdges)))
                        } else {
                            edges[writeNode] = newEdges
                        }
                    }
                } while !pendingRinglets.isEmpty
                print("Original Ringlets: \\(allRinglets.count)")
                print("\\(nodes.count) nodes!")
                print("\\(edges.reduce(0) { $0 + $1.value.count }) edges!")
                print("\\(initialNodes.count) initial nodes!")
                self.init(
                    nodes: Array(nodes),
                    edges: edges,
                    initialStates: initialNodes
                )
            }

        }
        """
    }

}
