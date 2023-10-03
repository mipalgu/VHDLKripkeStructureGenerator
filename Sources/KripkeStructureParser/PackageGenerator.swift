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
#if os(Linux)
import IO
#endif
import VHDLMachines
import VHDLParsing

public struct PackageGenerator {

    public init() {}

    public func swiftPackage<T>(representation: T) -> FileWrapper? where T: MachineVHDLRepresentable {
        let machine = representation.machine
        let name = machine.name.rawValue
        let cFileRawData = (["#include \"include/\(name)/\(name).h\""] + machine.states.map {
            VariableParser(state: $0, in: representation).functions.values.joined(separator: "\n\n")
        })
        .joined(separator: "\n\n")
        let cHeaderRawData = (
            [
                "#include <stdint.h>\n#include <stdbool.h>\n#ifndef \(name)_H\n#define \(name)_H\n" +
                "#ifdef __cplusplus\nextern \"C\" {\n#endif"
            ] +
            machine.states.map {
                VariableParser(state: $0, in: representation).definitions.values.joined(separator: "\n\n")
            } + ["#ifdef __cplusplus\n}\n#endif\n#endif // \(name)_H"]
        )
        .joined(separator: "\n\n")
        guard
            let cFileData = cFileRawData.data(using: .utf8),
            let cHeaderData = cHeaderRawData.data(using: .utf8),
            let packageData = String(machinePackage: representation).data(using: .utf8),
            let swiftExtensionsData = String.swiftExtensions.data(using: .utf8)
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
        cIncludeSubfolder.preferredFilename = "\(name)"
        let includeFolder = FileWrapper(directoryWithFileWrappers: ["C\(name)": cIncludeSubfolder])
        includeFolder.preferredFilename = "include"
        let cTargetFolder = FileWrapper(
            directoryWithFileWrappers: ["include": includeFolder, "\(name).c": cFile]
        )
        cTargetFolder.preferredFilename = "C\(name)"
        let swiftTargetFolder = FileWrapper(
            directoryWithFileWrappers: ["VHDLParsingExtensions.swift": swiftExtensions]
        )
        swiftTargetFolder.preferredFilename = "\(name)"
        let sourcesFolder = FileWrapper(
            directoryWithFileWrappers: ["C\(name)": cTargetFolder, "\(name)": swiftTargetFolder]
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
        let name = representation.machine.name.rawValue
        self = """
        // swift-tools-version:5.7

        import PackageDescription

        let package = Package(
            name: "\(name)",
            products: [
                .library(
                    name: "\(name)",
                    targets: ["\(name)"]
                )
            ],
            dependencies: [
                .package(url: "https://github.com/mipalgu/VHDLParsing.git", from: "2.4.0"),
            ],
            targets: [
                .target(
                    name: "C\(name)",
                    dependencies: []
                ),
                .target(
                    name: "\(name)",
                    dependencies: ["C\(name)", "VHDLParsing"]
                )
            ]
        )

        """
    }

}
