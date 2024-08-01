// WhenCase+constants.swift
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

extension WhenCase {

    @usableFromInline static let ringletCacheSmallInitial = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(
            reference: .variable(name: .initial)
        ))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .busy)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .waitForNewRinglets)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .memoryIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .ringletIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .we)),
                value: .literal(value: .bit(value: .low))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .di)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .isDuplicate)),
                value: .literal(value: .boolean(value: false))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentRingletIndex)),
                value: .literal(value: .integer(value: 0))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentRinglet)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [
                        IndexedValue(
                            index: .others,
                            value: .vector(value: .indexed(values: IndexedVector(
                                values: [IndexedValue(index: .others, value: .bit(value: .low))]
                            )))
                        )
                    ]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .currentRingletAddress)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .genIndex)),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                    values: [IndexedValue(index: .others, value: .bit(value: .low))]
                ))))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .isInitial)),
                value: .literal(value: .boolean(value: true))
            ))
        ])
    )

    @usableFromInline static let ringletCacheSmallSetRingletRAMValue = WhenCase(
        condition: .expression(expression: .reference(variable: .variable(
            reference: .variable(name: .setRingletRAMValue)
        ))),
        code: .blocks(blocks: [
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .genValue)),
                value: .reference(variable: .variable(reference: .variable(name: .cacheValue)))
            )),
            .statement(statement: .assignment(
                name: .variable(reference: .variable(name: .internalState)),
                value: .reference(variable: .variable(reference: .variable(name: .checkPreviousRinglets)))
            ))
        ])
    )

    init<T>(
        ringletCacheLargeInitialFor state: State, in representation: T
    ) where T: MachineVHDLRepresentable {
        self.init(
            condition: .expression(expression: .reference(variable: .variable(
                reference: .variable(name: .initial)
            ))),
            code: .blocks(blocks: [
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .busy)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .internalState)),
                    value: .reference(variable: .variable(reference: .variable(name: .waitForNewRinglets)))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .memoryIndex)),
                    value: .literal(value: .integer(value: 0))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .ringletIndex)),
                    value: .literal(value: .integer(value: 0))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .we)),
                    value: .literal(value: .bit(value: .low))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .di)),
                    value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                        values: [IndexedValue(index: .others, value: .bit(value: .low))]
                    ))))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .isDuplicate)),
                    value: .literal(value: .boolean(value: false))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .currentRingletAddress)),
                    value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                        values: [IndexedValue(index: .others, value: .bit(value: .low))]
                    ))))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .genIndex)),
                    value: .literal(value: .vector(value: .indexed(values: IndexedVector(
                        values: [IndexedValue(index: .others, value: .bit(value: .low))]
                    ))))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .isInitial)),
                    value: .literal(value: .boolean(value: true))
                )),
                .statement(statement: .assignment(
                    name: .variable(reference: .variable(name: .topIndex)),
                    value: .literal(value: .integer(value: max(0, state.encodedSize(in: representation) - 1)))
                ))
            ])
        )
    }

}
