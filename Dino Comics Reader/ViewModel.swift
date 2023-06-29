//
//  ViewModel.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/29/23.
//
import CloudKit
import Combine
import CoreData
import SwiftUI

class ComicViewModel: ObservableObject {
    @Published var comicId: Int
    @Published var currentUrl: String

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicIdHistory.timestamp, ascending: false)],
        animation: .default)
    private var backItems: FetchedResults<ComicIdHistory>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicIdForwardHistory.timestamp, ascending: false)],
        animation: .default)
    private var forwardItems: FetchedResults<ComicIdForwardHistory>

    private var context: NSManagedObjectContext
    private var cloudStoreDidChange: AnyCancellable?

    init(comicId: Int, currentUrl: String, context: NSManagedObjectContext) {
        self.comicId = comicId
        self.currentUrl = currentUrl
        self.context = context

        cloudStoreDidChange = NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                self?.handleCloudStoreChange()
            }
    }

    // TODO: is there a better way to do a navigation history stack?
    func navigateBack() {
        let fetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 2
        // get the second one since the first one will be my current one
        do {
            if let lastItem = try context.fetch(fetchRequest).last {
                let newForwardItem = ComicIdForwardHistory(context: context)
                newForwardItem.id = Int32(comicId)
                newForwardItem.timestamp = Date()

                comicId = Int(lastItem.id)
                currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"

                // Delete the last item from the back history
                context.delete(lastItem)
                try context.save()
            }
        } catch {
            print("Failed to fetch ComicIdBackHistory: \(error)")
        }
    }

    func navigateForward() {
        let fetchRequest: NSFetchRequest<ComicIdForwardHistory> = ComicIdForwardHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            if let nextItem = try context.fetch(fetchRequest).first {
                let newBackItem = ComicIdHistory(context: context)
                newBackItem.id = Int32(comicId)
                newBackItem.timestamp = Date()

                comicId = Int(nextItem.id)
                currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"

                // Delete the next item from the forward history
                context.delete(nextItem)
                try context.save()
            }
        } catch {
            print("Failed to fetch ComicIdForwardHistory: \(error)")
        }
    }

    func navigateTo(newComicId: Int) {
        let idItem = ComicIdHistory(context: context)
        print("Adding item with id \(newComicId) in webview completion callback")
        idItem.setValue(newComicId, forKey: "id")
        idItem.setValue(Date(), forKey: "timestamp")
        try? context.save()
        comicId = newComicId
        currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
    }

    func reflectNavigationTo(newComicId: Int) {
        // Called when the webview has navigated to a new comic, to keep track of this in the state
        let lastComicId = comicId
        comicId = newComicId
        currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
        // TODO: make a URL builder convenience Util func in a Utils file
        if lastComicId != newComicId || backItems.isEmpty {
            // this way we don't add a history item on a refresh or initial app load from a history state that we're already tracking as most recent page
            let idItem = ComicIdHistory(context: context)
            print("Adding item with id \(newComicId) in navigation callback")
            idItem.setValue(Date(), forKey: "timestamp")
            idItem.setValue(newComicId, forKey: "id")
            try? context.save()
        } else {
            print("Not adding back record for \(newComicId) since lastComicId was already this")
        }
    }

    private func handleCloudStoreChange() {
        // TODO: make this optional? have some way to reject remote changes?
        // Fetch the latest back and forward history items
        print("Reloading for change in cloud storage!")
        let backFetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
        backFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        backFetchRequest.fetchLimit = 1

        do {
            let lastBackItem = try context.fetch(backFetchRequest).first

            // Handle the changed data
            comicId = Int(lastBackItem!.id)
            currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"
        } catch {
            print("Failed to fetch history items: \(error)")
        }
    }
}
