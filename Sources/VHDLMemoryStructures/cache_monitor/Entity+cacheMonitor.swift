// Entity+CacheMonitor.swift
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

extension Entity {

    init?(cacheMonitorName name: VariableName, numberOfMembers members: Int, cache: Entity) {
        guard members > 1 else {
            return nil
        }
        let cacheSignals = cache.port.signals
        let cacheSignalNames = Set(cacheSignals.map(\.name))
        let expectedSignalNames: Set<VariableName> = [
            .address, .data, .we, .ready, .busy, .value, .valueEn, .lastAddress
        ]
        guard
            expectedSignalNames.allSatisfy({ cacheSignalNames.contains($0) }),
            let addressType = cacheSignals.first(where: { $0.name == .address })?.type,
            let dataType = cacheSignals.first(where: { $0.name == .data })?.type
        else {
            return nil
        }
        let cacheMemberSignals = cacheSignals.filter {
            expectedSignalNames.contains($0.name) && $0.name != .busy && $0.name != .lastAddress &&
                $0.name != .value && $0.name != .valueEn
        }
        let memberSignals = (0..<members).flatMap { member in
            let cacheSignals = cacheMemberSignals.map {
                PortSignal(
                    type: $0.type,
                    name: VariableName(rawValue: $0.name.rawValue + "\(member)")!,
                    mode: $0.mode
                )
            }
            return cacheSignals + [
                PortSignal(type: .stdLogic, name: VariableName(rawValue: "en\(member)")!, mode: .output)
            ]
        }
        let busy = PortSignal(type: .stdLogic, name: .busy, mode: .output)
        let lastAddress = PortSignal(type: addressType, name: .lastAddress, mode: .output)
        let value = PortSignal(type: dataType, name: .value, mode: .output)
        let valueEn = PortSignal(type: .stdLogic, name: .valueEn, mode: .output)
        let clk = PortSignal(type: .stdLogic, name: .clk, mode: .input)
        guard let block = PortBlock(
            signals: [clk] + memberSignals + [value, valueEn, busy, lastAddress]
        ) else {
            return nil
        }
        self.init(name: name, port: block)
    }

}
