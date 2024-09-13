// Entity+ArrangementRunner.swift
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

import VHDLGenerator
import VHDLMachines
import VHDLParsing

extension Entity {

    public init?<T>(
        arrangementRunerFor representation: T,
        machines: [VariableName: any MachineVHDLRepresentable]
    ) where T: ArrangementVHDLRepresentable {
        let arrangement = representation.arrangement
        let name = representation.name
        let externalsRead = arrangement.externalSignals.filter { $0.mode != .output }.map {
            PortSignal(
                type: $0.type,
                name: VariableName(rawValue: "READ_\($0.name.rawValue)")!,
                mode: .input
            )
        }
        let globalsRead = arrangement.signals.map {
            PortSignal(
                type: $0.type,
                name: VariableName(rawValue: "\(name.rawValue)_READ_\($0.name.rawValue)")!,
                mode: .input
            )
        }
        let externalsWrite = arrangement.externalSignals.filter { $0.mode != .input }.map {
            PortSignal(
                type: $0.type,
                name: VariableName(rawValue: "WRITE_\($0.name.rawValue)")!,
                mode: .output
            )
        }
        let globalsWrite = arrangement.signals.map {
            PortSignal(
                type: $0.type,
                name: VariableName(rawValue: "\(name.rawValue)_WRITE_\($0.name.rawValue)")!,
                mode: .output
            )
        }
        let mappings = arrangement.machines
        let machinesRaw: [(VariableName, any MachineVHDLRepresentable)] = mappings.keys.compactMap {
            guard let representation = machines[$0.type] else {
                return nil
            }
            return ($0.name, representation)
        }
        guard machinesRaw.count == mappings.count else {
            return nil
        }
        let representations = Dictionary(uniqueKeysWithValues: machinesRaw)
        let signals = representations.flatMap { name, representation in
            let statements = representation.architectureHead.statements
            let stateTypes: [Type] = statements.compactMap { statement -> Type? in
                switch statement {
                case .definition(value: .signal(let signal)):
                    guard signal.name == .currentState else {
                        return nil
                    }
                    return signal.type
                default:
                    return nil
                }
            }
            guard stateTypes.count == 1 else {
                fatalError("Cannot discern state type for \(name.rawValue)")
            }
            let stateType = stateTypes[0]
            let machine = representation.machine
            let machineName = representation.entity.name
            let snapshotExternals = machine.externalSignals.filter { $0.mode != .input }
            let readExternals = snapshotExternals.map {
                PortSignal(
                    type: $0.type,
                    name: VariableName(rawValue: "\(name)_READ_\(machineName)_\($0.name)")!,
                    mode: .input
                )
            }
            let readMachine = machine.machineSignals.map {
                PortSignal(
                    type: $0.type,
                    name: VariableName(rawValue: "\(name)_READ_\(machineName)_\($0.name)")!,
                    mode: .input
                )
            }
            let readState = machine.states.flatMap { state in
                state.signals.map {
                    PortSignal(
                        type: $0.type,
                        name: VariableName(
                            rawValue: "\(name)_READ_\(machineName)_STATE_\(state.name.rawValue)_\($0.name)"
                        )!,
                        mode: .input
                    )
                }
            }
            let readSnapshot = [
                PortSignal(
                    type: .boolean,
                    name: VariableName(rawValue: "\(name)_READ_executeOnEntry")!,
                    mode: .input
                ),
                PortSignal(
                    type: stateType,
                    name: VariableName(rawValue: "\(name)_READ_state")!,
                    mode: .input
                )
            ]
            let inputs = readExternals + readMachine + readState + readSnapshot
            let writeExternals = snapshotExternals.map {
                PortSignal(
                    type: $0.type,
                    name: VariableName(rawValue: "\(name)_WRITE_\(machineName)_\($0.name)")!,
                    mode: .output
                )
            }
            let writeMachine = machine.machineSignals.map {
                PortSignal(
                    type: $0.type,
                    name: VariableName(rawValue: "\(name)_WRITE_\(machineName)_\($0.name)")!,
                    mode: .output
                )
            }
            let writeState = machine.states.flatMap { state in
                state.signals.map {
                    PortSignal(
                        type: $0.type,
                        name: VariableName(
                            rawValue: "\(name)_WRITE_\(machineName)_STATE_\(state.name.rawValue)_\($0.name)"
                        )!,
                        mode: .output
                    )
                }
            }
            let writeSnapshot = [
                PortSignal(
                    type: .boolean,
                    name: VariableName(rawValue: "\(name)_WRITE_executeOnEntry")!,
                    mode: .output
                ),
                PortSignal(
                    type: stateType,
                    name: VariableName(rawValue: "\(name)_WRITE_state")!,
                    mode: .output
                )
            ]
            let outputs = writeExternals + writeMachine + writeState + writeSnapshot
            return inputs + outputs
        }
        guard let firstMachine = machines.first?.value.machine else {
            return nil
        }
        let firstClock = firstMachine.clocks[firstMachine.drivingClock]
        guard
            machines.allSatisfy({
                let clock = $0.value.machine.clocks[$0.value.machine.drivingClock]
                return clock.frequency == firstClock.frequency && clock.period == firstClock.period
            }),
            let drivingClock = arrangement.clocks.first(where: {
                $0.frequency == firstClock.frequency && $0.period == firstClock.period
            })
        else {
            return nil
        }
        let busySignal = [PortSignal(type: .stdLogic, name: .busy, mode: .output)]
        let readySignal = PortSignal(type: .stdLogic, name: .ready, mode: .input)
        let clockSignal = PortSignal(clock: drivingClock)
        let arrangementSignals = externalsRead + globalsRead + externalsWrite + globalsWrite
        let runnerInputs = [clockSignal, readySignal]
        self.init(
            name: VariableName(rawValue: "\(name)ArrangementRunner")!,
            port: PortBlock(signals: runnerInputs + arrangementSignals + signals + busySignal)!
        )
    }

}
