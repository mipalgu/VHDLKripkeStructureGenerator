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

extension ArchitectureHead {

    init?(
        cacheMonitorName name: VariableName,
        cacheName: VariableName,
        elementSize size: Int,
        numberOfElements: Int,
        selectors: Int
    ) {
        guard
            selectors > 0,
            let cache = Entity(cacheName: cacheName, elementSize: size, numberOfElements: numberOfElements),
            let internalStateTypeName = VariableName(rawValue: name.rawValue + "InternalState_t")
        else {
            return nil
        }
        let selectorCacheSignals = cache.port.signals.lazy.filter {
            $0.name != .clk && $0.name != .lastAddress
        }
        let cacheSignals = selectorCacheSignals.map {
            HeadStatement.definition(value: .signal(value: LocalSignal(
                type: $0.type, name: $0.name, defaultValue: $0.defaultValue, comment: $0.comment
            )))
        }
        let selectorOutputs = selectorCacheSignals.filter { $0.mode == .output }
        let selectorSignals = (0..<selectors).flatMap { selector in
            let cacheSignals = selectorOutputs.map {
                HeadStatement.definition(value: .signal(value: LocalSignal(
                    type: $0.type,
                    name: VariableName(rawValue: "last\($0.name.rawValue.capitalized)\(selector)")!,
                    defaultValue: $0.defaultValue,
                    comment: $0.comment
                )))
            }
            return cacheSignals + [
                HeadStatement.definition(value: .signal(value: LocalSignal(
                    type: .stdLogic,
                    name: VariableName(rawValue: "selector\(selector)_en")!,
                    defaultValue: .literal(value: .bit(value: .low)),
                    comment: nil
                )))
            ]
        }
        let cacheComponent = HeadStatement.definition(
            value: .component(value: ComponentDefinition(entity: cache))
        )
        let selectorInternalStates = (0..<selectors).compactMap {
            VariableName(rawValue: "CheckSelector\($0)")
        }
        guard
            selectorInternalStates.count == selectors,
            let enumeration = EnumerationDefinition(
                name: internalStateTypeName, nonEmptyValues: [.initial] + selectorInternalStates
            )
        else {
            return nil
        }
        let internalStateType = HeadStatement.definition(value: .type(
            value: .enumeration(value: enumeration)
        ))
        let internalStateDefinition = HeadStatement.definition(value: .signal(
            value: LocalSignal(
                type: .alias(name: internalStateTypeName),
                name: .internalState,
                defaultValue: .reference(variable: .variable(reference: .variable(name: .initial)))
            )
        ))
        self.init(
            statements: cacheSignals + selectorSignals + [
                internalStateType, internalStateDefinition, cacheComponent
            ]
        )
    }

}
