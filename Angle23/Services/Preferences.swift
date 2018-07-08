//
//  Preferences.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation


class Preferences {

    static let didUpdatePreferencesNotification = NSNotification.Name("didUpdatePreferences")

    static var imagesFolderPath: URL {
        get {
            guard let path = UserDefaults.standard.url(forKey: "imagesFolderPath") else {
                return defaultImagesFolderPath
            }
            return path
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "imagesFolderPath")
            UserDefaults.standard.synchronize()
            sendPreferencesUpdate()
        }
    }

    private static var defaultImagesFolderPath: URL {
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
    }

    private static func sendPreferencesUpdate() {
        NotificationCenter.default.post(name: didUpdatePreferencesNotification, object: nil)
    }

}
