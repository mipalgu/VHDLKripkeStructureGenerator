// VHDLFile+cacheMonitor.swift
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
extension VHDLFile {

    /// Create a `VHDL` file for a cache monitor.
    /// 
    /// A cache monitor is a file that arbitrates access to a cache when multiple entities are trying to
    /// access it simultaneously. The cache monitor adopts a round-robin schedule to determine which entity
    /// has access to the cache at any point in time. This schedule is not strictly enforced by the monitor
    /// but instead requires each entity to relinquish access to move onto the next entity. This design
    /// ensures a lightweight implementation that does not require a central arbiter to manage priorities and
    /// timeout requirements or adopt time-based scheduling windows that can create inefficient access. This
    /// does, however, require all entites to be aware of this fact and relinquish access when not using the
    /// cache as continuous access can result in starvation for all other entities.
    /// 
    /// To request access to the cache, an entity must assert the `ready` signal `high` at the start and
    /// during the entire operation of the cache. The cache monitor will assert the appropriate `en` signal
    /// (en0, en1, en2, etc.) to signify which entity has access to the cache at each point in time. The
    /// `value` and `value_en` signals are shared between all entities but only represent valid data for a
    /// specific entity when their respective `en` is `high`.
    /// 
    /// When changing the current entity using the cache, the monitor will give a 1-cycle switching
    /// window to ensure that the entity can respond within enough time to obtain ownership of the cache. The
    /// values within the very first clock cycle where `en` is `high` may represent junk data as the cache is
    /// providing this timing window and the cache contains a 1-cycle read-window starting with the updated
    /// signals from the new entity. Please ensure you leave a 1-cycle window on the very first access of the
    /// cache to ensure that the cache monitor can switch entities without data corruption.
    /// - Parameters:
    ///   - name: The name of the monitor.
    ///   - members: The number of entities that have access to the cache.
    ///   - cache: The cache this monitor is managing.
    @inlinable
    public init?(cacheMonitorName name: VariableName, numberOfMembers members: Int, cache: Entity) {
        guard
            let entity = Entity(cacheMonitorName: name, numberOfMembers: members, cache: cache),
            let architecture = Architecture(cacheMonitorName: name, numberOfMembers: members, cache: cache)
        else {
            return nil
        }
        self.init(
            architectures: [architecture],
            entities: [entity],
            includes: [.library(value: .ieee), .include(statement: .stdLogic1164)]
        )
    }

}
