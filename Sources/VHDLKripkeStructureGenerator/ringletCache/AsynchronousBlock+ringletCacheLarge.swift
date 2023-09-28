// AsynchronousBlock+ringletCacheLarge.swift
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

extension AsynchronousBlock {

    init?<T>(
        ringletCacheLargeFor state: State,
        in representation: T,
        ringletsPerAddress: Int,
        maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        guard
            let block = ProcessBlock(
                ringletCacheLargeFor: state,
                in: representation,
                ringletsPerAddress: ringletsPerAddress,
                maxExecutionSize: maxExecutionSize
            )
        else {
            return nil
        }
        let entity = Entity(bramFor: state, in: representation)
        let machine = representation.machine
        let clk = machine.clocks[machine.drivingClock].name
        let component = ComponentInstantiation(
            label: VariableName(rawValue: "bram_inst")!,
            name: entity.name,
            port: PortMap(variables: [
                VariableMap(
                    lhs: .variable(reference: .variable(name: clk)),
                    rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: clk))))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: .we)),
                    rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: .we))))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: .addr)),
                    rhs: .expression(value: .reference(variable: .variable(
                        reference: .variable(name: .index)
                    )))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: .di)),
                    rhs: .expression(value: .reference(variable: .variable(reference: .variable(name: .di))))
                ),
                VariableMap(
                    lhs: .variable(reference: .variable(name: .do)),
                    rhs: .expression(value: .reference(variable: .variable(
                        reference: .variable(name: .value)
                    )))
                )
            ])
        )
        let indexAssignment = AsynchronousBlock.statement(statement: .assignment(
            name: .variable(reference: .variable(name: .index)),
            value: .whenBlock(value: .whenElse(statement: WhenElseStatement(
                value: .reference(variable: .variable(reference: .variable(name: .readAddress))),
                condition: [
                    Expression.conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .ready))),
                        rhs: .literal(value: .bit(value: .high))
                    ))),
                    .reference(variable: .variable(reference: .variable(name: .read))),
                    .conditional(condition: .comparison(value: .equality(
                        lhs: .reference(variable: .variable(reference: .variable(name: .internalState))),
                        rhs: .reference(variable: .variable(reference: .variable(name: .waitForNewRinglets)))
                    )))
                ].joined { Expression.logical(operation: .and(lhs: $0, rhs: $1)) },
                elseBlock: .expression(value: .reference(variable: .variable(
                    reference: .variable(name: .genIndex)
                )))
            )))
        ))
        self = .blocks(blocks: [
            .component(block: component),
            indexAssignment,
            .process(block: block)
        ])
    }

}

extension ProcessBlock {

    init?<T>(
        ringletCacheLargeFor state: State,
        in representation: T,
        ringletsPerAddress: Int,
        maxExecutionSize: Int? = nil
    ) where T: MachineVHDLRepresentable {
        let clk = representation.machine.clocks[representation.machine.drivingClock].name
        self.init(
            sensitivityList: [clk],
            code: .ifStatement(block: .ifStatement(
                condition: .conditional(condition: .edge(value: .rising(expression: .reference(
                    variable: .variable(reference: .variable(name: clk))
                )))),
                ifBlock: .caseStatement(block: CaseStatement(
                    condition: .reference(variable: .variable(reference: .variable(name: .internalState))),
                    cases: [
                        WhenCase(ringletCacheLargeInitialFor: state, in: representation),
                        .othersNull
                    ]
                ))
            ))
        )
    }

}
