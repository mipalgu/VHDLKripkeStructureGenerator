// StringTests.swift
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

@testable import KripkeStructureParser
import VHDLMachines
import VHDLParsing
import XCTest

/// Test class for `String` extensions.
final class StringTests: XCTestCase {

    /// The representation of the `PingMachine`.
    let pingRepresentation = MachineRepresentation(machine: .pingMachine, name: .pingMachine)!

    /// Test the `read` state is created correctly.
    func testReadStateCreation() {
        let result = String(readStateFor: .waitForPong, in: pingRepresentation)
        let expected = """
        import CPingMachine
        import VHDLParsing

        public struct WaitForPongRead: Equatable, Hashable, Codable, Sendable {

            public var PingMachine_ping: LogicLiteral

            public var pong: LogicLiteral

            public var executeOnEntry: Bool

            public init(PingMachine_ping: LogicLiteral, pong: LogicLiteral, executeOnEntry: Bool) {
                self.PingMachine_ping = PingMachine_ping
                self.pong = pong
                self.executeOnEntry = executeOnEntry
            }

            public init?(value: UInt32) {
                guard PingMachine_isValid(value), PingMachine_WaitForPong_isValid(value) else {
                    return nil
                }
                let PingMachine_pingValue = PingMachine_WaitForPong_READ_PingMachine_ping(value)
                let pongValue = PingMachine_WaitForPong_READ_pong(value)
                let executeOnEntryValue = PingMachine_WaitForPong_READ_executeOnEntry(value)
                guard
                    let PingMachine_pingLiteral = LogicLiteral(value: PingMachine_pingValue, numberOfBits: 2),
                    let pongLiteral = LogicLiteral(value: pongValue, numberOfBits: 2),
                    let executeOnEntryLiteral = Bool(value: executeOnEntryValue, numberOfBits: 1)
                else {
                    return nil
                }
                self.init(
                    PingMachine_ping: PingMachine_pingLiteral,
                    pong: pongLiteral,
                    executeOnEntry: executeOnEntryLiteral
                )
            }

        }

        """
        XCTAssertEqual(result, expected, "\(result.difference(from: expected))")
    }

    /// Test `WRITE` kripke state is defined correctly.
    func testWriteStateCreation() {
        let result = String(writeStateFor: .waitForPong, in: pingRepresentation)
        let expected = """
        import CPingMachine
        import VHDLParsing

        public struct WaitForPongWrite: Equatable, Hashable, Codable, Sendable {

            public var ping: LogicLiteral

            public var nextState: LogicVector

            public var executeOnEntry: Bool

            public init(ping: LogicLiteral, nextState: LogicVector, executeOnEntry: Bool) {
                self.ping = ping
                self.nextState = nextState
                self.executeOnEntry = executeOnEntry
            }

            public init?(value: UInt32) {
                guard PingMachine_isValid(value), PingMachine_WaitForPong_isValid(value) else {
                    return nil
                }
                let pingValue = PingMachine_WaitForPong_WRITE_ping(value)
                let nextStateValue = PingMachine_WaitForPong_WRITE_nextState(value)
                let executeOnEntryValue = PingMachine_WaitForPong_WRITE_executeOnEntry(value)
                guard
                    let pingLiteral = LogicLiteral(value: pingValue, numberOfBits: 2),
                    let nextStateBitVector = BitVector(value: nextStateValue, numberOfBits: 1),
                    let executeOnEntryLiteral = Bool(value: executeOnEntryValue, numberOfBits: 1)
                else {
                    return nil
                }
                let nextStateLiteral = LogicVector(
                    values: nextStateBitVector.values.map { LogicLiteral(bit: $0) }
                )
                self.init(
                    ping: pingLiteral,
                    nextState: nextStateLiteral,
                    executeOnEntry: executeOnEntryLiteral
                )
            }

        }

        """
        XCTAssertEqual(result, expected, "\(result.difference(from: expected))")
    }

    /// Test Ringlet representation in Kripke Structure.
    func testRingletCreation() {
        let result = String(kripkeNodeFor: .waitForPong, in: pingRepresentation)
        let expected = """
        import CPingMachine
        import VHDLParsing

        public struct WaitForPongRinglet: Equatable, Hashable, Codable, Sendable {

            public var read: WaitForPongRead

            public var write: WaitForPongWrite

            public init(read: WaitForPongRead, write: WaitForPongWrite) {
                self.read = read
                self.write = write
            }

            public init?(value: UInt32) {
                guard
                    let read = WaitForPongRead(value: value),
                    let write = WaitForPongWrite(value: value)
                else {
                    return nil
                }
                self.init(read: read, write: write)
            }

        }

        """
        XCTAssertEqual(result, expected)
    }

}
