//
//  Path+Zip.swift
//  FileZipKit
//
//  Created by Eric Marchand on 01/11/2017.
//  Copyright © 2017 Eric Marchand. All rights reserved.
//

import Foundation
import FileKit
import ZIPFoundation

extension Path {

    /// Zip current path to destination.
    /// - Throws:
    ///     `FileKitError.fileAlreadyExists`: if destination exists
    ///     `FileKitError.fileDoesNotExist`: if current path do not exists
    ///     `Archive.ArchiveError.unwritableArchive`
    ///     `Archive.ArchiveError.invalidStartOfCentralDirectoryOffset`
    ///     ...
    public func zip(to destination: Path, shouldKeepParent: Bool = true, progress: Progress? = nil) throws {
        if destination.exists {
            throw FileKitError.fileAlreadyExists(path: destination)
        }
        if !self.exists {
            throw FileKitError.fileDoesNotExist(path: self)
        }
        try FileManager.default.zipItem(at: self.url, to: destination.url, shouldKeepParent: shouldKeepParent, progress: progress)
    }

    /// Unzip current path to destination.
    /// - Throws:
    ///     `FileKitError.fileDoesNotExist`: if current path do not exists
    ///     `Archive.ArchiveError.unreadableArchive`
    ///     `Archive.ArchiveError.invalidEntryPath`
    ///     `Archive.ArchiveError.invalidCompressionMethod`
    ///     ...
    public func unzip(to destination: Path) throws {
        if !self.exists {
            throw FileKitError.fileDoesNotExist(path: self)
        }
        if !destination.parent.exists {
            try destination.createDirectory(withIntermediateDirectories: true)
        }
        do {
            try FileManager.default.unzipItem(at: self.url, to: destination.url)
        } catch let error as Archive.ArchiveError {
            throw error
        } catch {
            throw FileKitError.readFromFileFail(path: self, error: error)
        }
    }
}

// MARK: Archive
extension Path {

    /// Get a zip archive from path.
    public func archive(mode: Archive.AccessMode) -> Archive? {
        return Archive(path: self, mode: mode)
    }

}

extension Archive {

    /// Init an archive from `Path`.
    public convenience init?(path: Path, mode: Archive.AccessMode) {
        self.init(url: path.url, accessMode: mode)
    }

    /// Extract an entry to `path`
    public func extract(_ entry: Entry, to path: Path, bufferSize: Int = defaultReadChunkSize) throws -> CRC32 {
        return try self.extract(entry, to: path.url, bufferSize: bufferSize)
    }

    /// Add a path to zip archive.
    public func addEntry(with path: Path, type: Entry.EntryType, permissions: UInt16? = nil,
                         compressionMethod: CompressionMethod = .none, bufferSize: Int = defaultWriteChunkSize,
                         progress: Progress? = nil) throws {
        let data = try File<Data>(path: path).read()
        try self.addEntry(with: path.fileName,
                          type: type,
                          uncompressedSize: Int64(data.count),
                          modificationDate: path.modificationDate ?? path.creationDate ?? Date(),
                          permissions: permissions,
                          compressionMethod: compressionMethod,
                          bufferSize: bufferSize,
                          progress: progress,
                          provider: { (position: Int64, size: Int) in
            return data.subdata(in: Int(position)..<(Int(position)+size))
        })
    }
}

// MARK: Sequence

extension Sequence where Element == Path {

    /// Zip a list of `Path`
    func zip(to destination: Path, update: Bool = false, compressionMethod: CompressionMethod = .none) throws -> Archive? {
        var mode: Archive.AccessMode = .create
        if destination.exists {
            if update {
                mode = .update
            } else {
                try destination.deleteFile()
            }
        }
        var iterator = makeIterator()
        var path = iterator.next()

        guard let archive = destination.archive(mode: mode) else {
            return nil
        }
        while path != nil {
            if let path = path {
                /*let entry = */try archive.addEntry(with: path, type: .file, compressionMethod: compressionMethod)
            }
            path = iterator.next()
        }
        return archive
    }

}
