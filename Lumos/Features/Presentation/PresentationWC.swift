//
//  PresentationWC.swift
//  Lumos
//
//  Created by Christoph Pageler on 01.08.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Cocoa


class PresentationWC: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()

        (NSApp.delegate as? AppDelegate)?.presentationWindowController = self
    }

}
