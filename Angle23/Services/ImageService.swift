//
//  ImageService.swift
//  Angle23
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import RealmSwift


class ImageService {

    static let shared = ImageService()

    static let didUpdateImageNotification = NSNotification.Name("didUpdateImageNotification")

    private init() {

    }

    private func realmForImageFolderPath() -> Realm? {
        return try? Realm(fileURL: Preferences.imagesFolderPath.appendingPathComponent("Store.realm"))
    }

    public func allImages() -> [ImageModel] {
        guard let result = allImagesAsResult() else {
            return []
        }
        return Array(result)
    }

    public func allImagesAsResult() -> Results<ImageModel>? {
        return realmForImageFolderPath()?.objects(ImageModel.self)
    }

    private func minViewCount() -> Int? {
        guard let realm = realmForImageFolderPath() else { return nil }
        return realm.objects(ImageModel.self).min(ofProperty: "viewCount")
    }

    public func write(_ closure: () -> Void) {
        try? realmForImageFolderPath()?.write {
            closure()
        }
    }

    public func cleanImageStore() {
        let path = Preferences.imagesFolderPath.path
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }
        let imagesInFolder = files.filter({ $0.hasSuffix(".jpg") })
        var keepEventImageModelsWithUUID: [String] = []

        for imagePath in imagesInFolder {
            let filename = URL(fileURLWithPath: imagePath).lastPathComponent
            if let eventImageModel = imageModelWith(filename: filename) {
                // exists
                keepEventImageModelsWithUUID.append(eventImageModel.uuid)
            } else {
                // create new event image model
                let eventImageModel = createImageModelWith(filename: filename)
                keepEventImageModelsWithUUID.append(eventImageModel.uuid)
            }
        }

        cleanImageModelsExcept(uuids: keepEventImageModelsWithUUID)
    }

}

// MARK: - Model Operations

extension ImageService {

    public func imageModelWith(filename: String) -> ImageModel? {
        return realmForImageFolderPath()?
            .objects(ImageModel.self)
            .filter("filename = '\(filename)'")
            .first
    }

    public func imageModelWith(filepath: String) -> ImageModel? {
        let filename = URL(fileURLWithPath: filepath).lastPathComponent
        return imageModelWith(filename: filename)
    }

    @discardableResult
    public func createImageModelWith(filename: String, closure: ((ImageModel) -> Void)? = nil) -> ImageModel {
        let creationDate = creationDateForFileWith(filename: filename)

        let imageModel = ImageModel()
        imageModel.filename = filename
        imageModel.createdDate = creationDate
        imageModel.viewCount = minViewCount() ?? 0

        closure?(imageModel)

        let realm = realmForImageFolderPath()
        try? realm?.write {
            realm?.add(imageModel)
        }
        sendDidUpdateImageNotification()

        return imageModel
    }

    @discardableResult
    public func createImageModelWith(filepath: String, closure: ((ImageModel) -> Void)? = nil) -> ImageModel {
        let filename = URL(fileURLWithPath: filepath).lastPathComponent
        return createImageModelWith(filename: filename, closure: closure)
    }

    private func cleanImageModelsExcept(uuids: [String]) {
        guard let realm = realmForImageFolderPath() else { return }
        var didUpdate = false
        for imageModel in realm.objects(ImageModel.self) {
            if !uuids.contains(imageModel.uuid) {
                try! realm.write {
                    realm.delete(imageModel)
                }
                didUpdate = true
            }
        }
        if didUpdate {
            sendDidUpdateImageNotification()
        }
    }

    public func removeImageModelWith(filename: String) {
        guard let imageModel = imageModelWith(filename: filename) else { return }
        guard let realm = realmForImageFolderPath() else { return }

        try! realm.write {
            realm.delete(imageModel)
        }

        sendDidUpdateImageNotification()
    }

    public func removeImageModelWith(filepath: String) {
        let filename = URL(fileURLWithPath: filepath).lastPathComponent
        removeImageModelWith(filename: filename)
    }

}

// MARK: - File Operations

private extension ImageService {

    private func fullPathForFileWith(filename: String) -> String {
        return Preferences.imagesFolderPath.appendingPathComponent(filename).path
    }

    private func creationDateForFileWith(filename: String) -> Date {
        let filepath = Preferences.imagesFolderPath.appendingPathComponent(filename).path
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: filepath) else { return Date() }
        guard let creationDate = attributes[.creationDate] as? Date else { return Date() }
        return creationDate
    }

}

// MARK: - Notification

private extension ImageService {

    func sendDidUpdateImageNotification() {
        NotificationCenter.default.post(name: ImageService.didUpdateImageNotification, object: nil, userInfo: nil)
    }

}


// MARK: - Image Queue

extension ImageService {

    func fetchNextImageFromQueue() -> ImageModel? {
        let sortDescriptors = [
            SortDescriptor(keyPath: "viewCount", ascending: true),
            SortDescriptor(keyPath: "lastViewedDate", ascending: true)
        ]
        let nextImage = allImagesAsResult()?
            .filter("show == true")
            .sorted(by: sortDescriptors).first
        write {
            nextImage?.viewCount += 1
        }
        sendDidUpdateImageNotification()
        return nextImage
    }

}
