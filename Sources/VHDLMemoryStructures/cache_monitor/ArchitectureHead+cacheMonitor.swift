// ArchitectureHead+cacheMonitor.swift
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
extension ArchitectureHead {

    /// Create a cache monitor architecture head.
    /// - Parameters:
    ///   - name: The name of the cache monitor.
    ///   - members: The number of members that have access to the cache.
    ///   - cache: The cache entity.
    @inlinable
    init?(cacheMonitorName name: VariableName, numberOfMembers members: Int, cache: Entity) {
        guard members > 0 else {
            return nil
        }
        let cacheDefinition = HeadStatement.definition(value: .component(
            value: ComponentDefinition(entity: cache)
        ))
        guard members > 1 else {
            self.init(statements: [cacheDefinition])
            return
        }
        let cacheSignals = cache.port.signals
        let cacheSignalNames = Set(cacheSignals.map(\.name))
        let expectedSignalNames: Set<VariableName> = [
            .address, .data, .we, .ready, .busy, .value, .valueEn, .lastAddress
        ]
        guard
            expectedSignalNames.allSatisfy({ cacheSignalNames.contains($0) }),
            let addressType = cacheSignals.first(where: { $0.name == .address })?.type,
            let dataType = cacheSignals.first(where: { $0.name == .data })?.type,
            let internalStateType = VariableName(rawValue: name.rawValue + "InternalState_t"),
            let internalStateCases = EnumerationDefinition(
                name: internalStateType,
                nonEmptyValues: [.initial, .chooseAccess, .waitWhileBusy]
            )
        else {
            return nil
        }
        let internalStateTypeDefinition = HeadStatement.definition(value: .type(value: .enumeration(
            value: internalStateCases
        )))
        let enablesType = SignalType.ranged(type: .stdLogicVector(size: .downto(
            upper: .literal(value: .integer(value: members - 1)),
            lower: .literal(value: .integer(value: 0))
        )))
        let signals = [
            LocalSignal(type: addressType, name: .address),
            LocalSignal(type: dataType, name: .data),
            LocalSignal(type: .stdLogic, name: .we),
            LocalSignal(type: .stdLogic, name: .ready),
            LocalSignal(type: enablesType, name: .enables),
            LocalSignal(type: enablesType, name: .lastEnabled),
            LocalSignal(
                type: .alias(name: internalStateType),
                name: .internalState,
                defaultValue: .reference(variable: .variable(reference: .variable(name: .initial)))
            )
        ]
        .map { HeadStatement.definition(value: .signal(value: $0)) }
        self.init(statements: [internalStateTypeDefinition] + signals + [cacheDefinition])
    }

}
