//
//  FolderWatch.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import Witness


class FolderWatch {

    static let shared = FolderWatch()

    private var witness: Witness?

    private init() {
        initFolderWatch()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(notificationDidUpdatePreferencesNotification),
                                               name: Preferences.didUpdatePreferencesNotification,
                                               object: nil)
    }

    @objc private func notificationDidUpdatePreferencesNotification(_ notification: Notification) {
        initFolderWatch()
    }

    private func initFolderWatch() {
        witness?.flush()
        witness = nil

        witness = Witness(paths: [Preferences.imagesFolderPath.path],
                          flags: .FileEvents,
                          latency: 0.3,
                          changeHandler:
        { fileEvents in
            for fileEvent in fileEvents {
                self.handleFileEvent(fileEvent)
            }
        })
    }

    private func handleFileEvent(_ fileEvent: FileEvent) {
        let listenToFlags: FileEventFlags = [.ItemCreated, .ItemRemoved, .ItemRenamed]
        guard !fileEvent.flags.intersection(listenToFlags).isEmpty else { return }
        let path = fileEvent.path
        guard path.hasSuffix(".jpg") else { return }
        guard Preferences.imagesFolderPath.path == URL(fileURLWithPath: path).deletingLastPathComponent().path else { return }

        if FileManager.default.fileExists(atPath: fileEvent.path) {
            if ImageService.shared.imageModelWith(filepath: fileEvent.path) == nil {
                ImageService.shared.createImageModelWith(filepath: fileEvent.path) { imageModel in
                    imageModel.uploadedFrom = "Filesystem"
                }
            }
        } else {
            ImageService.shared.removeImageModelWith(filepath: fileEvent.path)
        }
    }

}
