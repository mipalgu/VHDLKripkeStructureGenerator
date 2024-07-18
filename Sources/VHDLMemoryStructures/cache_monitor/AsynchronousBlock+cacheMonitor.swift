// AsynchronousBlock+cacheMonitor.swift
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

import Utilities
import VHDLParsing

/// Add cache monitor creation.
extension AsynchronousBlock {

    // swiftlint:disable function_body_length

    /// Create a cache monitor block.
    /// - Parameters:
    ///   - name: The name of the cache monitor.
    ///   - members: The number of members that have access to the cache.
    ///   - cache: The cache entity to monitor.
    @inlinable
    init?(cacheMonitorName name: VariableName, numberOfMembers members: Int, cache: Entity) {
        guard members > 0 else {
            return nil
        }
        let expectedSignalNames: Set<VariableName> = [
            .address, .data, .we, .ready, .busy, .value, .valueEn, .lastAddress
        ]
        let cacheSignalNames = Set(cache.port.signals.map(\.name))
        guard expectedSignalNames.allSatisfy({ cacheSignalNames.contains($0) }) else {
            return nil
        }
        // swiftlint:disable force_unwrapping
        guard members > 1 else {
            self.init(cacheMonitorSingularName: name, cache: cache)
            return
        }
        guard let process = ProcessBlock(cacheMonitorNumberOfMembers: members) else {
            return nil
        }
        let mappedSignals = cache.port.signals.map {
            VariableMap(
                lhs: .variable(reference: .variable(name: $0.name)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: $0.name))))
            )
        }
        let component = AsynchronousBlock.component(block: ComponentInstantiation(
            label: .cacheInst, name: cache.name, port: PortMap(variables: mappedSignals)
        ))
        let memberAssignments = (0..<members).map {
            AsynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(name: VariableName(rawValue: "en\($0)")!)),
                value: .expression(value: .reference(variable: .indexed(
                    name: .reference(variable: .variable(reference: .variable(name: .enables))),
                    index: .index(value: .literal(value: .integer(value: $0)))
                )))
            ))
        }
        let othersLow = Expression.literal(value: .vector(value: .indexed(values: IndexedVector(
            values: [IndexedValue(index: .others, value: .literal(value: .bit(value: .low)))]
        ))))
        let low = Expression.literal(value: .bit(value: .low))
        let cacheAssignmentSignals: [(VariableName, Expression)] = [
            (.address, othersLow), (.data, othersLow), (.we, low), (.ready, low)
        ]
        let cacheAssignmentNames = cacheAssignmentSignals.map { signal, defaultValue in
            (
                (0..<members).map { ($0, VariableName(rawValue: signal.rawValue + "\($0)")!) },
                signal,
                defaultValue
            )
        }
        let assignments = cacheAssignmentNames.map {
            let statements = $0.map {
                AsynchronousExpression.whenBlock(value: .when(statement: WhenStatement(
                    condition: .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .indexed(
                            name: .reference(variable: .variable(reference: .variable(name: .enables))),
                            index: .index(value: .literal(value: .integer(value: $0)))
                        )),
                        rhs: .literal(value: .bit(value: .high))
                    ))),
                    value: .reference(variable: .variable(reference: .variable(name: $1)))
                )))
            } + [AsynchronousExpression.expression(value: $2)]
            let expression = statements.reversed().joined {
                guard case .whenBlock(let when) = $1, case .when(let statement) = when else {
                    fatalError("Impossible!")
                }
                return AsynchronousExpression.whenBlock(value: .whenElse(statement: WhenElseStatement(
                    value: statement.value,
                    condition: statement.condition,
                    elseBlock: $0
                )))
            }
            return AsynchronousBlock.statement(statement: .assignment(
                name: .variable(reference: .variable(name: $1)),
                value: expression
            ))
        }
        // swiftlint:enable force_unwrapping
        self = .blocks(blocks: [component] + memberAssignments + assignments + [.process(block: process)])
    }

    // swiftlint:enable function_body_length

    /// Create a cache monitor with 1 member.
    /// - Parameters:
    ///   - name: The name of the monitor.
    ///   - cache: The cache it monitors.
    @inlinable
    init?(cacheMonitorSingularName name: VariableName, cache: Entity) {
        // swiftlint:disable force_unwrapping
        let expectedSignals: Set<VariableName> = [.address, .data, .we, .ready]
        let signalNames = cache.port.signals.map(\.name)
        guard expectedSignals.allSatisfy({ signalNames.contains($0) }) else {
            return nil
        }
        let mappedSignals = cache.port.signals.map {
            let rawName = expectedSignals.contains($0.name) ? $0.name.rawValue + "0" : $0.name.rawValue
            return VariableMap(
                lhs: .variable(reference: .variable(name: $0.name)),
                rhs: .expression(value: .reference(variable: .variable(reference: .variable(
                    name: VariableName(rawValue: rawName)!
                ))))
            )
        }
        let component = ComponentInstantiation(
            label: .cacheInst, name: cache.name, port: PortMap(variables: mappedSignals)
        )
        self = .blocks(blocks: [
            .component(block: component),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: VariableName(rawValue: "en0")!)),
                value: .expression(value: .literal(value: .bit(value: .high)))
            ))
        ])
        // swiftlint:enable force_unwrapping
    }

}
