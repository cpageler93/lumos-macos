//
//  ImageModel+Image.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import AppKit


extension ImageModel {

    public func imageData() -> NSImage? {
        let url = Preferences.imagesFolderPath.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return NSImage(data: data)
    }

}
