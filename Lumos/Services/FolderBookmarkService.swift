//
//  FolderBookmarkService.swift
//  Lumos
//
//  Created by Christoph Pageler on 08.07.18.
//  Copyright © 2018 Christoph Pageler. All rights reserved.
//


import Foundation


class FolderBookmarkService {

    static let shared = FolderBookmarkService()

    private var bookmarks: [URL: Data] = [:]

    private init() {
        
    }

    public func saveBookmarksData() {
        let path = getBookmarkPath()
        NSKeyedArchiver.archiveRootObject(bookmarks, toFile: path)
    }

    func storeFolderInBookmark(url: URL) {
        do {
            let data = try url.bookmarkData(options: NSURL.BookmarkCreationOptions.withSecurityScope,
                                            includingResourceValuesForKeys: nil, relativeTo: nil)
            bookmarks[url] = data
        } catch {
            print("Error storing bookmarks")
        }
    }

    func getBookmarkPath() -> String {
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        url = url.appendingPathComponent("Bookmarks.dict")
        return url.path
    }

    func loadBookmarks() {
        let path = getBookmarkPath()
        guard let bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [URL: Data] else { return }
        for bookmark in bookmarks {
            restoreBookmark(bookmark)
        }
    }

    func restoreBookmark(_ bookmark: (key: URL, value: Data)) {
        let restoredUrl: URL?
        var isStale = false

        print("Restoring \(bookmark.key)")
        do {
            restoredUrl = try URL.init(resolvingBookmarkData: bookmark.value,
                                       options: NSURL.BookmarkResolutionOptions.withSecurityScope,
                                       relativeTo: nil,
                                       bookmarkDataIsStale: &isStale)
        } catch {
            print("Error restoring bookmarks")
            restoredUrl = nil
        }

        if let url = restoredUrl {
            if isStale {
                print("URL is stale")
            } else {
                if !url.startAccessingSecurityScopedResource() {
                    print("Couldn't access: \(url.path)")
                }
            }
        }

    }


}
