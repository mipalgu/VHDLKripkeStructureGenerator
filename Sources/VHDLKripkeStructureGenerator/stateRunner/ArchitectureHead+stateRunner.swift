// ArchitectureHead+stateRunner.swift
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
import VHDLMachines
import VHDLParsing

/// Add state runner.
extension ArchitectureHead {

    // swiftlint:disable force_unwrapping

    @inlinable
    init?<T>(stateRunnerFor state: State, in representation: T) where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let executionSize = state.executionSize(in: representation)
        let preamble = "\(state.name.rawValue)_"
        let allArrays = [
            (VariableName(pre: preamble, name: .readSnapshotsType)!, Type.alias(name: .readSnapshotType)),
            (VariableName(pre: preamble, name: .writeSnapshotsType)!, Type.alias(name: .writeSnapshotType)),
            (VariableName(pre: preamble, name: .targetsType)!, Type.signal(type: machine.statesEncoding)),
            (VariableName(pre: preamble, name: .finishedType)!, .signal(type: .boolean)),
            (
                VariableName(pre: preamble, name: .ringletsWorkingType)!,
                .alias(name: VariableName(pre: preamble, name: .ringletType)!)
            ),
            (VariableName(pre: preamble, name: .pendingStatesType)!, .signal(type: machine.statesEncoding))
        ]
        let typeDefinitions = allArrays.map {
            HeadStatement(array: ArrayDefinition(name: $0.0, size: [executionSize], elementType: $0.1))
        }
        guard
            let ringletRunnerEntity = Entity(ringletRunnerFor: representation),
            let stateGenerator = Entity(stateKripkeGeneratorFor: state, in: representation),
            let expander = Entity(ringletExpanderFor: state, in: representation),
            let writeSnapshot = Record(writeSnapshotFor: state, in: representation),
            let internalSignals = HeadStatement.stateRunnerInternals(for: state, in: representation)
        else {
            return nil
        }
        let snapshotTrackers = writeSnapshot.types.filter { $0.name != .nextState }.map {
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: $0.type, name: VariableName(rawValue: "current\($0.name.rawValue.capitalized)")!
            )))
        }
        let components = [ringletRunnerEntity, stateGenerator, expander].map {
            HeadStatement.definition(value: .component(
                value: ComponentDefinition(name: $0.name, port: $0.port)
            ))
        }
        self.init(statements: typeDefinitions + snapshotTrackers + internalSignals + components)
    }

    // swiftlint:enable force_unwrapping

}

/// Add helpers.
extension HeadStatement {

    /// The `hasStarted` signal.
    @usableFromInline static let hasStarted = HeadStatement.definition(value: .signal(value: LocalSignal(
        type: .boolean, name: .hasStarted
    )))

    /// The `reset` signal
    @usableFromInline static let reset = HeadStatement.definition(value: .signal(value: LocalSignal(
        type: .stdLogic, name: .reset, defaultValue: .literal(value: .bit(value: .low))
    )))

    /// Create an array definition.
    /// - Parameter array: The array that is defined.
    @inlinable
    init(array: ArrayDefinition) {
        self = .definition(value: .type(value: .array(value: array)))
    }

    // swiftlint:disable force_unwrapping

    /// Create the internal signals for the state runner.
    /// - Parameters:
    ///   - state: The state to create the runner for.
    ///   - representation: The machine representation to use.
    /// - Returns: The internals signal definitions for the state runner.
    @inlinable
    static func stateRunnerInternals<T>(
        for state: State, in representation: T
    ) -> [HeadStatement]? where T: MachineVHDLRepresentable {
        guard let representationStateType = representation.stateType else {
            return nil
        }
        let preamble = "\(state.name.rawValue)_"
        let previousRinglet = HeadStatement.definition(value: .signal(
            value: LocalSignal(type: representationStateType, name: .previousRinglet)
        ))
        return [.hasStarted, .reset, previousRinglet] + [
            (VariableName.readSnapshots, VariableName.readSnapshotsType),
            (.writeSnapshots, .writeSnapshotsType),
            (.targets, .targetsType),
            (.finished, .finishedType)
        ].map {
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: .alias(name: VariableName(pre: preamble, name: $0.1)!),
                name: VariableName(pre: preamble, name: $0.0)!
            )))
        }
    }

    // swiftlint:enable force_unwrapping

}
