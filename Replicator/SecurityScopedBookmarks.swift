//
//  SecurityScopedBookmarks.swift
//  Replicator
//
//  Created by leslie on 10/19/24.
//  Copyright © 2024 jamf. All rights reserved.
//

import Cocoa

class SecurityScopedBookmarks: NSObject {
    
    static let shared = SecurityScopedBookmarks()
    
    func allowAccess(for urlString: String) -> Bool {
        logFunctionCall()
        
        let allBookmarks = fetchBookmarks()
        
        guard let bookmarkData = allBookmarks[urlString] else {
            print("Bookmark data for \(urlString) does not exist.")
            return false
        }
        
        do {
            var isStale = false
            let fileURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                print("Bookmark for \(urlString) is stale, needs to be recreated.")
            }

            if fileURL.startAccessingSecurityScopedResource() {
                print("Accessed security-scoped resource for \(urlString).")
            } else {
                print("Could not access security-scoped resource for \(urlString).")
                return false
            }
        } catch {
            print("Error resolving bookmark for \(urlString): \(error)")
            return false
        }
        return true
    }
    
    func create(for fileUrl: URL) {
        logFunctionCall()
        var bookmarks = fetchBookmarks()
//        let fileUrl = URL(fileURLWithPath: filePath)
        
        do {
            let bookmarkData = try fileUrl.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            bookmarks[fileUrl.path()] = bookmarkData
        } catch {
            print("Error creating bookmark for \(fileUrl.path()): \(error)")
        }
        userDefaults.set(bookmarks, forKey: "bookmarks")
    }
    
    func fetchBookmarks() -> [String: Data] {
        logFunctionCall()
        if fm.fileExists(atPath: AppInfo.bookmarksPath) {
            AppInfo.bookmarks = NSKeyedUnarchiver.unarchiveObject(withFile: AppInfo.bookmarksPath) as? [URL: Data] ?? [:]
            var currentBookmarks = [String: Data]()
            for (url, bookmarkData) in AppInfo.bookmarks {
                do {
                    var isStale = false
                    let _ = try URL(
                        resolvingBookmarkData: bookmarkData,
                        options: [.withSecurityScope],
                        relativeTo: nil,
                        bookmarkDataIsStale: &isStale
                    )

                    if isStale {
                        print("Bookmark for \(url.path()) is stale, needs to be recreated.")
                    } else {
                        print("Register bookmark for \(url.path()).")
                        currentBookmarks[url.path()] = bookmarkData
                    }

                } catch {
                    print("Error resolving bookmark for \(url.path()): \(error)")
                }
            }
            userDefaults.set(currentBookmarks, forKey: "bookmarks")
            try? FileManager.default.moveItem(at: URL(fileURLWithPath: AppInfo.bookmarksPath, isDirectory: true), to: URL(fileURLWithPath: AppInfo.bookmarksPath + ".migrated", isDirectory: true))
        }
        
        guard let savedBookmarks = userDefaults.dictionary(forKey: "bookmarks") as? [String: Data] else {
            return [:]
        }
        for (urlString, _) in savedBookmarks {
            print("found bookmark for: \(urlString)")
        }
        
        return savedBookmarks
    }

}
