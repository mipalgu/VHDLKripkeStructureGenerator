// VHDLKripkeStructureGenerator.swift
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

import Foundation
#if os(Linux)
import IO
#endif
import KripkeStructureParser
import VHDLKripkeStructureGeneratorProtocols
import VHDLMachines
import VHDLParsing

public struct VHDLKripkeStructureGenerator: KripkeStructureGenerator {

    public init() {}

    public func generate<T>(representation: T) -> [VHDLFile] where T: MachineVHDLRepresentable {
        let machine = representation.machine
        guard
            let verifiedMachine = VHDLFile(verifiable: representation),
            let runner = VHDLFile(runnerFor: representation),
            let ringletRunner = VHDLFile(ringletRunnerFor: representation),
            let types = VHDLFile(typesFor: representation),
            let generator = VHDLFile(generatorFor: representation)
        else {
            return []
        }
        // let primitiveTypes = VHDLFile.primitiveTypes
        let states = machine.states
        let bramInterface = VHDLFile(bramInterfaceFor: representation)
        let stateFiles: [[VHDLFile]] = states.compactMap {
            guard
                let expander = VHDLFile(ringletExpanderFor: $0, in: representation),
                let kripkeGenerator = VHDLFile(stateKripkeGeneratorFor: $0, in: representation),
                let runner = VHDLFile(stateRunnerFor: $0, in: representation),
                let cache = VHDLFile(ringletCacheFor: $0, in: representation),
                let stateGenerator = VHDLFile(stateGeneratorFor: $0, in: representation)
            else {
                return nil
            }
            return [
                expander, kripkeGenerator, runner, VHDLFile(bramFor: $0, in: representation), cache,
                stateGenerator
            ]
        }
        guard stateFiles.count == states.count else {
            return []
        }
        return [verifiedMachine, runner, ringletRunner, types, generator, bramInterface] +
            stateFiles.flatMap { $0 }
    }

    public func generatePackage<T>(representation: T) -> FileWrapper? where T: MachineVHDLRepresentable {
        let generator = PackageGenerator()
        return generator.swiftPackage(representation: representation)
    }

    public func generateAll<T>(representation: T) -> FileWrapper? where T: MachineVHDLRepresentable {
        let vhdlFiles = self.generate(representation: representation)
        let vhdlData: [(String, FileWrapper)] = vhdlFiles.compactMap { file in
            guard let data = file.rawValue.data(using: .utf8) else {
                return nil
            }
            let name: String
            if let entity = file.entities.first {
                name = entity.name.rawValue
            } else if let package = file.packages.first {
                name = package.name.rawValue
            } else {
                return nil
            }
            let wrapper = FileWrapper(regularFileWithContents: data)
            wrapper.preferredFilename = "\(name).vhd"
            return ("\(name).vhd", wrapper)
        }
        let name = representation.machine.name.rawValue
        guard
            vhdlData.count == vhdlFiles.count,
            let package = self.generatePackage(representation: representation),
            let primitiveTypesData = String.primitiveTypes.data(using: .utf8)
        else {
            return nil
        }
        let primitiveTypes = FileWrapper(regularFileWithContents: primitiveTypesData)
        primitiveTypes.preferredFilename = "PrimitiveTypes.vhd"
        let vhdlFolder = FileWrapper(
            directoryWithFileWrappers: Dictionary(
                uniqueKeysWithValues: vhdlData + [("PrimitiveTypes.vhd", primitiveTypes)]
            )
        )
        vhdlFolder.preferredFilename = "vhdl"
        let packageFolder = FileWrapper(directoryWithFileWrappers: ["\(name)": package])
        packageFolder.preferredFilename = "\(name)"
        let parent = FileWrapper(
            directoryWithFileWrappers: ["vhdl": vhdlFolder, "\(name)": packageFolder]
        )
        return parent
    }

}
