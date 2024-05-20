// PackageGenerator.swift
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
import SwiftUtils
import VHDLMachines
import VHDLParsing

public struct PackageGenerator {

    public init() {}

    public func swiftPackage<T>(representation: T) -> FileWrapper? where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let name = representation.entity.name.rawValue
        let cFileRawData = (["#include \"include/C\(name)/\(name).h\""] +
        [String(isValidImplementationFor: representation)] +
            machine.states.sorted { $0.name < $1.name }.flatMap {
                [
                    VariableParser(state: $0, in: representation).functions
                        .sorted { $0.0 < $1.0 }.map { $0.1 }.joined(separator: "\n\n"),
                    String(isValidStateImplementationFor: $0, in: representation)
                ]
            }
        )
        .joined(separator: "\n\n")
        let cHeaderRawData = (
            [
                "#include <stdint.h>\n#include <stdbool.h>\n#ifndef \(name)_H\n#define \(name)_H\n" +
                "#ifdef __cplusplus\nextern \"C\" {\n#endif"
            ] + [String(isValidDefinitionFor: representation)] +
            machine.states.sorted { $0.name < $1.name }.flatMap {
                [
                    VariableParser(state: $0, in: representation)
                        .definitions.sorted { $0.0 < $1.0 }.map { $0.1 }.joined(separator: "\n\n"),
                    String(isValidStateDefinitionFor: $0, in: representation)
                ]
            } + ["#ifdef __cplusplus\n}\n#endif\n#endif // \(name)_H"]
        )
        .joined(separator: "\n\n")
        let stateFilesRaw = machine.states.flatMap {
            [
                ("\($0.name.rawValue)Read.swift", String(readStateFor: $0, in: representation)),
                ("\($0.name.rawValue)Write.swift", String(writeStateFor: $0, in: representation)),
                ("\($0.name.rawValue)Ringlet.swift", String(kripkeNodeFor: $0, in: representation))
            ]
        }
        let stateFiles: [(String, FileWrapper)] = stateFilesRaw.compactMap {
            guard let fileData = $0.1.data(using: .utf8) else {
                return nil
            }
            let fileWrapper = FileWrapper(regularFileWithContents: fileData)
            fileWrapper.preferredFilename = $0.0
            return ($0.0, fileWrapper)
        }
        guard
            stateFiles.count == stateFilesRaw.count,
            let cFileData = cFileRawData.data(using: .utf8),
            let cHeaderData = cHeaderRawData.data(using: .utf8),
            let packageData = String(machinePackage: representation).data(using: .utf8),
            let swiftExtensionsData = String.swiftExtensions.data(using: .utf8),
            let kripkeParserData = String(kripkeParserFor: representation).data(using: .utf8),
            let kripkeStructureData = String(kripkeStructureFor: representation).data(using: .utf8),
            let parserData = String(parserFor: representation).data(using: .utf8),
            let vhdlKripkeStructureData = String(vhdlKripkeStructureFor: representation)?.data(using: .utf8)
        else {
            return nil
        }
        let cFile = FileWrapper(regularFileWithContents: cFileData)
        cFile.preferredFilename = "\(name).c"
        let cHeader = FileWrapper(regularFileWithContents: cHeaderData)
        cHeader.preferredFilename = "\(name).h"
        let package = FileWrapper(regularFileWithContents: packageData)
        package.preferredFilename = "Package.swift"
        let swiftExtensions = FileWrapper(regularFileWithContents: swiftExtensionsData)
        swiftExtensions.preferredFilename = "VHDLParsingExtensions.swift"
        let cIncludeSubfolder = FileWrapper(directoryWithFileWrappers: ["\(name).h": cHeader])
        cIncludeSubfolder.preferredFilename = "C\(name)"
        let includeFolder = FileWrapper(directoryWithFileWrappers: ["C\(name)": cIncludeSubfolder])
        includeFolder.preferredFilename = "include"
        let cTargetFolder = FileWrapper(
            directoryWithFileWrappers: ["include": includeFolder, "\(name).c": cFile]
        )
        cTargetFolder.preferredFilename = "C\(name)"
        let swiftTargetFolder = FileWrapper(
            directoryWithFileWrappers: Dictionary(
                uniqueKeysWithValues: [
                    ("VHDLParsingExtensions.swift", swiftExtensions),
                    ("\(name)KripkeParser.swift", FileWrapper(regularFileWithContents: kripkeParserData)),
                    (
                        "\(name)KripkeStructure.swift",
                        FileWrapper(regularFileWithContents: kripkeStructureData)
                    ),
                    (
                        "KripkeStructure+init.swift",
                        FileWrapper(regularFileWithContents: vhdlKripkeStructureData)
                    )
                ] + stateFiles
            )
        )
        swiftTargetFolder.preferredFilename = "\(name)"
        let parserTargetFolder = FileWrapper(directoryWithFileWrappers: [
            "Parser.swift": FileWrapper(regularFileWithContents: parserData)
        ])
        let sourcesFolder = FileWrapper(
            directoryWithFileWrappers: [
                "C\(name)": cTargetFolder, "\(name)": swiftTargetFolder, "Parser": parserTargetFolder
            ]
        )
        sourcesFolder.preferredFilename = "Sources"
        let packageFolder = FileWrapper(
            directoryWithFileWrappers: ["Sources": sourcesFolder, "Package.swift": package]
        )
        packageFolder.preferredFilename = "\(name)"
        return packageFolder
    }

}

extension String {

    init<T>(machinePackage representation: T) where T: MachineVHDLRepresentable {
        let name = representation.entity.name.rawValue
        self = """
        // swift-tools-version:5.7

        import PackageDescription

        let package = Package(
            name: "\(name)",
            products: [
                .library(
                    name: "\(name)",
                    targets: ["\(name)"]
                ),
                .executable(name: "\(name.lowercased())_parser", targets: ["Parser"])
            ],
            dependencies: [
                .package(url: "https://github.com/mipalgu/VHDLParsing.git", from: "2.4.0"),
                .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
                .package(url: "https://github.com/cpslabgu/VHDLKripkeStructures.git", from: "1.0.0")
            ],
            targets: [
                .target(
                    name: "C\(name)",
                    dependencies: []
                ),
                .target(
                    name: "\(name)",
                    dependencies: ["C\(name)", "VHDLParsing"]
                ),
                .executableTarget(name: "Parser", dependencies: [
                    .target(name: "\(name)"),
                    .product(name: "ArgumentParser", package: "swift-argument-parser")
                ])
            ]
        )

        """
    }

}
