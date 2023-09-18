// Package+primitiveTypes.swift
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

import VHDLParsing

/// Add helper packages for Kripke structure generation.
extension VHDLPackage {

    // swiftlint:disable force_unwrapping

    /// The `PrimitiveTypes` package.
    static let primitiveTypes = VHDLPackage(
        name: .primitiveTypes,
        statements: [
            .definition(value: .type(value: .array(value: ArrayDefinition(
                name: .stdLogicTypesT,
                size: [
                    .to(
                        lower: .literal(value: .integer(value: 0)), upper: .literal(value: .integer(value: 8))
                    )
                ],
                elementType: .signal(type: .stdLogic)
            )))),
            .definition(value: .constant(value: ConstantSignal(
                name: .stdLogicTypes,
                type: .alias(name: .stdLogicTypesT),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(values: [
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 0))),
                        value: .logic(value: .uninitialized)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 1))),
                        value: .logic(value: .unknown)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 2))),
                        value: .logic(value: .low)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 3))),
                        value: .logic(value: .high)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 4))),
                        value: .logic(value: .highImpedance)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 5))),
                        value: .logic(value: .weakSignal)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 6))),
                        value: .logic(value: .weakSignalLow)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 7))),
                        value: .logic(value: .weakSignalHigh)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 8))),
                        value: .logic(value: .dontCare)
                    )
                ]))))
            )!)),
            .definition(value: .type(value: .array(value: ArrayDefinition(
                name: .bitTypesT,
                size: [
                    .to(
                        lower: .literal(value: .integer(value: 0)), upper: .literal(value: .integer(value: 1))
                    )
                ],
                elementType: .signal(type: .bit)
            )))),
            .definition(value: .constant(value: ConstantSignal(
                name: .bitTypes,
                type: .alias(name: .bitTypesT),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(values: [
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 0))),
                        value: .literal(value: .bit(value: .low))
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 1))),
                        value: .literal(value: .bit(value: .high))
                    )
                ]))))
            )!)),
            .definition(value: .type(value: .array(value: ArrayDefinition(
                name: .booleanTypesT,
                size: [
                    .to(
                        lower: .literal(value: .integer(value: 0)), upper: .literal(value: .integer(value: 1))
                    )
                ],
                elementType: .signal(type: .boolean)
            )))),
            .definition(value: .constant(value: ConstantSignal(
                name: .booleanTypes,
                type: .alias(name: .booleanTypesT),
                value: .literal(value: .vector(value: .indexed(values: IndexedVector(values: [
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 0))),
                        value: .boolean(value: false)
                    ),
                    IndexedValue(
                        index: .index(value: .literal(value: .integer(value: 1))),
                        value: .boolean(value: true)
                    )
                ]))))
            )!)),
            .definition(value: .function(value: FunctionDefinition(
                name: .boolToStdLogic,
                arguments: [ArgumentDefinition(name: .value, type: .signal(type: .boolean))],
                returnType: .signal(type: .stdLogic)
            ))),
            .definition(value: .function(value: FunctionDefinition(
                name: .stdLogicToBool,
                arguments: [ArgumentDefinition(name: .value, type: .signal(type: .stdLogic))],
                returnType: .signal(type: .boolean)
            ))),
            .definition(value: .function(value: FunctionDefinition(
                name: .stdLogicEncoded,
                arguments: [ArgumentDefinition(name: .value, type: .signal(type: .stdLogic))],
                returnType: .signal(type: .ranged(type: .stdLogicVector(size: .downto(
                    upper: .literal(value: .integer(value: 1)),
                    lower: .literal(value: .integer(value: 0))
                ))))
            ))),
            .definition(value: .function(value: FunctionDefinition(
                name: .stdULogicEncoded,
                arguments: [ArgumentDefinition(name: .value, type: .signal(type: .stdULogic))],
                returnType: .signal(type: .ranged(type: .stdLogicVector(size: .downto(
                    upper: .literal(value: .integer(value: 1)),
                    lower: .literal(value: .integer(value: 0))
                ))))
            )))
        ]
    )

    // swiftlint:enable force_unwrapping

}
