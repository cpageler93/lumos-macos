//
//  ImageModel+Image.swift
//  Lumos
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import AppKit


extension ImageModel {

    public func absoluteFileURL() -> URL {
        return Preferences.imagesFolderPath.appendingPathComponent(filename)
    }

    public func absoluteFileURLForThumbnail() -> URL {
        let fileURL = absoluteFileURL()

        var thumbnailURL = fileURL.deletingLastPathComponent()
        thumbnailURL.appendPathComponent(Preferences.databaseName)
        thumbnailURL.appendPathComponent("thumbnails")
        thumbnailURL.appendPathComponent(fileURL.lastPathComponent)

        return thumbnailURL
    }

    public func imageData() -> Data? {
        let url = absoluteFileURL()
        return try? Data(contentsOf: url)
    }

    public func thumbnailData() -> Data? {
        let url = absoluteFileURLForThumbnail()
        return try? Data(contentsOf: url)
    }

    public func nsImage() -> NSImage? {
        guard let data = imageData() else { return nil }
        return NSImage(data: data)
    }

    public func hasThumbnail() -> Bool {
        let thumbnailURL = absoluteFileURLForThumbnail()
        let thumbnailPath = thumbnailURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: thumbnailPath,
                                                 withIntermediateDirectories: false,
                                                 attributes: nil)
        return FileManager.default.fileExists(atPath: thumbnailURL.absoluteString)
    }

}
