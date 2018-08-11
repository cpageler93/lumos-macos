//
//  Preferences.swift
//  Lumos
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
        }
    }

    static func checkImageFolderPath() {
        if !FileManager.default.fileExists(atPath: imagesFolderPath.path) {
            UserDefaults.standard.set(nil, forKey: "imagesFolderPath")
            UserDefaults.standard.synchronize()
        }
    }

    static var databaseName: String {
        get {
            guard let name = UserDefaults.standard.string(forKey: "databaseName") else {
                return defaultDatabaseName
            }
            return name
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "databaseName")
            UserDefaults.standard.synchronize()
        }
    }

    private static var defaultImagesFolderPath: URL {
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Pictures")
    }

    private static var defaultDatabaseName: String {
        return "Database.lms"
    }

    public static func resetToDefaultDatabaseName() {
        UserDefaults.standard.set(nil, forKey: "databaseName")
        UserDefaults.standard.synchronize()
    }

    public static func sendPreferencesUpdate() {
        NotificationCenter.default.post(name: didUpdatePreferencesNotification, object: nil)
    }

}
