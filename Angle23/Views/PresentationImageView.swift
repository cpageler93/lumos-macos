//
//  PresentationImageView.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import AppKit


open class PresentationImageView: NSView {

    var image: NSImage? = nil {
        didSet {
            setNeedsDisplay(bounds)
        }
    }

    open override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if let image = image {
            let scaledImage = image.scaled(to: bounds.size,
                                           scalingMode: .aspectFill)
            scaledImage.draw(in: bounds)
        } else {
            let path = NSBezierPath(rect: bounds)
            NSColor.black.setFill()
            path.fill()
        }
    }

}

