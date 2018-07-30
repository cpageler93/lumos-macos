//
//  ImageService.swift
//  Lumos
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation
import AppKit
import RealmSwift


class ImageService {

    static let shared = ImageService()

    static let didUpdateImageNotification = NSNotification.Name("didUpdateImageNotification")

    public private(set) var isUpdatingThumbnails: Bool = false
    private var shouldUpdateThumbnails: Bool = false

    private init() {

    }

    private func realmForImageFolderPath() -> Realm? {
        return try? Realm(fileURL: Preferences.imagesFolderPath.appendingPathComponent("Store.realm"))
    }

    public func refresh() {
        guard let realm = realmForImageFolderPath() else { return }
        realm.refresh()
    }

    private func minSortViewCount() -> Int? {
        guard let realm = realmForImageFolderPath() else { return nil }
        return realm.objects(ImageModel.self).min(ofProperty: "sortViewCount")
    }

    public func write(_ closure: () -> Void) {
        guard let realm = realmForImageFolderPath() else { return }
        do {
            try realm.write {
                closure()
            }
            realm.refresh()
        } catch {
            print("write failed: \(error)")
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
        updateThumbnails()
    }

}
 
// MARK: - Model Operations

extension ImageService {

    public func allImages() -> [ImageModel] {
        guard let result = allImagesAsResult() else {
            return []
        }
        return Array(result)
    }

    public func allImagesAsResult() -> Results<ImageModel>? {
        return realmForImageFolderPath()?
            .objects(ImageModel.self)
    }

    public func imageModelWith(filename: String) -> ImageModel? {
        return realmForImageFolderPath()?
            .objects(ImageModel.self)
            .filter("filename = '\(filename)'")
            .first
    }

    public func imageModelWith(uuid: String) -> ImageModel? {
        return realmForImageFolderPath()?
            .objects(ImageModel.self)
            .filter("uuid = '\(uuid)'")
            .first
    }

    public func imageModelWith(filepath: String) -> ImageModel? {
        let filename = URL(fileURLWithPath: filepath).lastPathComponent
        return imageModelWith(filename: filename)
    }

    @discardableResult
    public func createImageModelWith(filename: String, closure: ((ImageModel) -> Void)? = nil) -> ImageModel {
        refresh()
        
        let creationDate = creationDateForFileWith(filename: filename)

        let imageModel = ImageModel()
        imageModel.filename = filename
        imageModel.createdDate = creationDate
        imageModel.sortViewCount = minSortViewCount() ?? 0

        closure?(imageModel)

        let realm = realmForImageFolderPath()
        try? realm?.write {
            realm?.add(imageModel)
        }
        sendDidUpdateImageNotification()
        updateThumbnails()

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
        updateThumbnails()
    }

    public func removeImageModelWith(filepath: String) {
        let filename = URL(fileURLWithPath: filepath).lastPathComponent
        removeImageModelWith(filename: filename)
    }

    public func addNewImage(_ imageData: Data, fromUserWithName username: String) {
        refresh()
        
        let imageModel = ImageModel()
        imageModel.filename = "\(imageModel.uuid).jpg"
        imageModel.createdDate = Date()
        imageModel.sortViewCount = minSortViewCount() ?? 0
        imageModel.uploadedFrom = username

        let filepath = fullPathForFileWith(filename: imageModel.filename)
        do {
            try imageData.write(to: URL(fileURLWithPath: filepath))
        } catch {
            return
        }

        let realm = realmForImageFolderPath()
        try? realm?.write {
            realm?.add(imageModel)
        }
        sendDidUpdateImageNotification()
        updateThumbnails()
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
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: ImageService.didUpdateImageNotification, object: nil, userInfo: nil)
        }
    }

}

// MARK: - Image Queue

extension ImageService {

    func fetchNextImageFromQueue() -> ImageModel? {
        let sortDescriptors = [
            SortDescriptor(keyPath: "sortViewCount", ascending: true),
            SortDescriptor(keyPath: "createdDate", ascending: true)
        ]
        var nextImage = allImagesAsResult()?
            .filter("show == true")
            .sorted(by: sortDescriptors).first
        if let firstNotSeen = allImagesAsResult()?.filter("lastViewedDate == nil").first {
            print("replace next image with new not seen \(firstNotSeen.uuid)")
            nextImage = firstNotSeen
        }
        write {
            nextImage?.sortViewCount += 1
            nextImage?.totalViewCount += 1
            nextImage?.lastViewedDate = Date()
        }
        sendDidUpdateImageNotification()
        return nextImage
    }

}

// MARK: - Thumbnails

extension ImageService {

    public func updateThumbnails() {
        shouldUpdateThumbnails = true
        guard !isUpdatingThumbnails else { return }
        isUpdatingThumbnails = true
        shouldUpdateThumbnails = false
        let dispatchQueue = DispatchQueue(label: "de.pageler.christoph.lumos.macos.imageservice.updatethumbnails",
                                          qos: .background,
                                          attributes: .concurrent,
                                          autoreleaseFrequency: .inherit,
                                          target: nil)
        dispatchQueue.async {
            for image in self.allImages() {
                if !image.hasThumbnail() {
                    if let nsImage = image.nsImage() {
                        let resizedImage = nsImage.scaled(to: CGSize(width: 100, height: 100))
                        if let resizedData = resizedImage.tiffRepresentation {
                            let imageRep = NSBitmapImageRep(data: resizedData)
                            if let jpgImage = imageRep?.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:]) {
                                try? jpgImage.write(to: image.absoluteFileURLForThumbnail())
                            }
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                self.isUpdatingThumbnails = false
                if self.shouldUpdateThumbnails {
                    self.updateThumbnails()
                }
            }
        }
    }

}
