#!/usr/bin/env xcrun swift -F Carthage/Build/Mac

import Foundation

protocol Streamable {
    var title: String { get }
    var body: String { get }
}

extension Streamable {
    var writableString: String {
        return "# \(title)\n\n\(body)"
    }
}

struct License: Streamable {
    let libraryName: String
    let legalText: String

    var title: String {
        return libraryName
    }

    var body: String {
        return legalText
    }
}

func getLicense(_ URL: URL) throws -> License {
    let legalText = try String(contentsOf: URL, encoding: .utf8)
    let pathComponents = URL.pathComponents
    let libraryName = pathComponents[pathComponents.count - 2]
    return License(libraryName: libraryName, legalText: legalText)
}

func run() throws {

    let carthageDir = "Pods"
    let outputFile = "LICENSES.md"
    let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]

    let fileManager = FileManager.default

    // Get URL’s for all files in carthageDir

    guard let carthageDirURL = URL(string: carthageDir),
          let carthageEnumerator = fileManager.enumerator(at: carthageDirURL, includingPropertiesForKeys: nil, options: options, errorHandler: nil)
    else {
        print("Error: \(carthageDir) directory not found. Please run `rake`")
        return
    }

    guard let carthageURLs = carthageEnumerator.allObjects as? [URL] else {
        print("Unexpected error: Enumerator contained item that is not URL.")
        return
    }

    let allURLs = carthageURLs

    // Get just the LICENSE files and convert them to License structs

    let licenseURLs = allURLs.filter { url in
        
        /*let pods = url.pathComponents.filter { $0 == "Pods" }
        if !pods.isEmpty {
            return false
        }*/
        
        return url.lastPathComponent.range(of: "LICENSE") != nil || url.lastPathComponent.range(of: "LICENCE") != nil
    }

    let licenses = licenseURLs.flatMap { try? getLicense($0) }

    let html = licenses.map { $0.writableString }.joined(separator: "\n\n")

    try html.write(toFile: outputFile, atomically: false, encoding: .utf8)
}

func main() {
    do {
        try run()
    } catch let error as NSError {
        print(error.localizedDescription)
    }
}

main()
