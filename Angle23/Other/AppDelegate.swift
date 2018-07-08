//
//  AppDelegate.swift
//  Angle23
//
//  Created by Christoph Pageler on 07.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var settingsWindowController: NSWindowController? = nil

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        FolderBookmarkService.shared.loadBookmarks()
        Server.shared.start()
        let _ = FolderWatch.shared
        ImageService.shared.cleanImageStore()

        // Load Settings VC
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main") , bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "SettingsVC")
        settingsWindowController = storyboard.instantiateController(withIdentifier: identifier) as? NSWindowController
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func openPreferences(_ sender: NSMenuItem) {
        settingsWindowController?.showWindow(nil)
    }

}

