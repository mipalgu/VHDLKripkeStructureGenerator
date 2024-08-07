// VHDLFile+stateGenerator.swift
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

extension VHDLFile {

    public init?<T>(
        stateGeneratorFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        self.init(sequentialStateGeneratorFor: state, in: representation, maxExecutionSize: maxExecutionSize)
    }

    public init?<T>(
        concurrentStateGeneratorFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        guard
            let body = AsynchronousBlock(
                stateGeneratorFor: state, in: representation, maxExecutionSize: maxExecutionSize
            ),
            let head = ArchitectureHead(
                stateGeneratorFor: state, in: representation, maxExecutionSize: maxExecutionSize
            ),
            let entity = Entity(stateGeneratorFor: state, in: representation),
            let typesInclude = UseStatement(
                rawValue: "use work.\(representation.entity.name.rawValue)Types.all;"
            )
        else {
            return nil
        }
        let includes = [
            Include.library(value: .ieee),
            .include(statement: .stdLogic1164),
            .include(statement: typesInclude),
            .include(statement: .primitiveTypes)
        ]
        self.init(
            architectures: [Architecture(body: body, entity: entity.name, head: head, name: .behavioral)],
            entities: [entity],
            includes: includes
        )
    }

    public init?<T>(
        sequentialStateGeneratorFor state: State, in representation: T, maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        guard
            let body = AsynchronousBlock(
                sequentialStateGeneratorFor: state, in: representation, maxExecutionSize: maxExecutionSize
            ),
            let head = ArchitectureHead(
                sequentialStateGeneratorFor: state, in: representation, maxExecutionSize: maxExecutionSize
            ),
            let entity = Entity(sequentialStateGeneratorFor: state, in: representation),
            let typesInclude = UseStatement(
                rawValue: "use work.\(representation.entity.name.rawValue)Types.all;"
            )
        else {
            return nil
        }
        let includes = [
            Include.library(value: .ieee),
            .include(statement: .stdLogic1164),
            .include(statement: .numericStd),
            .include(statement: typesInclude),
            .include(statement: .primitiveTypes)
        ]
        self.init(
            architectures: [Architecture(body: body, entity: entity.name, head: head, name: .behavioral)],
            entities: [entity],
            includes: includes
        )
    }

}
