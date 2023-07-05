//
//  ViewModel.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/29/23.
//
import CloudKit
import CoreData
import SwiftUI

class ComicViewModel: ObservableObject {
    @Published var comicId: Int32
    @Published var currentUrl: String
    @Published var isFavorite: Bool
    @Published var altText1: String
    @Published var altText2: String
    @Published var altText3: String

    private var altTextComicId: Int32?

    private var context: NSManagedObjectContext

    private var timer: Timer?

    init(context: NSManagedObjectContext) {
        do {
            let positionFetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
            positionFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            positionFetchRequest.fetchLimit = 1
            let lastItem = try context.fetch(positionFetchRequest).first
            let comicId = Int32(lastItem?.id ?? 2801)
            self.comicId = comicId
            self.currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"
            print("Fetched comicId \(comicId) from store from record with timestamp \(String(describing: lastItem?.timestamp))")
            let favoriteFetchRequest: NSFetchRequest<ComicFavorite> = ComicFavorite.fetchRequest()
            favoriteFetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: comicId))
            let favoriteResult = try context.fetch(favoriteFetchRequest)
            self.isFavorite = !(favoriteResult.isEmpty)
        } catch {
            print("Failed to fetch ComicIdBackHistory: \(error)")
            let comicId = Int32(2702)
            self.comicId = comicId
            self.currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"
            self.isFavorite = false
        }

        self.context = context
        // dumb defaults for the following before we load the webview to fetch them since we don't store them in coredata state
        self.altText1 = ""
        self.altText2 = ""
        self.altText3 = ""

        // TODO: set a second periodic timer? And for that one add an invalidation stopTimer() method that the View can hook into if it goes away
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
            self.refresh()
        })
    }

    // TODO: is there a better way to do a navigation history stack?
    func navigateBack() {
        let fetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 2
        // get the second one since the first one will be my current one
        do {
            let results = try context.fetch(fetchRequest)
            if let lastItem = results.last, let currentItem = results.first {
                let newForwardItem = ComicIdForwardHistory(context: context)
                newForwardItem.id = Int32(comicId)
                newForwardItem.timestamp = Date()

                comicId = lastItem.id
                currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"

                context.delete(currentItem)
                try context.save()
                print("Saving context navigating back to \(comicId)")
            }
        } catch {
            print("Failed to fetch ComicIdBackHistory: \(error)")
        }
        updateFavoriteStatus()
        showMostRecentHistory(limit: 10, desc: "from navigateBack")
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

                comicId = nextItem.id
                currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"

                // Delete the next item from the forward history
                context.delete(nextItem)
                try context.save()
            }
        } catch {
            print("Failed to fetch ComicIdForwardHistory: \(error)")
        }
        updateFavoriteStatus()
        showMostRecentHistory(limit: 10, desc: "from navigateForward")
    }

    func navigateTo(newComicId: Int32) {
        let idItem = ComicIdHistory(context: context)
        print("Adding item with id \(newComicId) in webview completion callback")
        idItem.setValue(newComicId, forKey: "id")
        idItem.setValue(Date(), forKey: "timestamp")
        try? context.save()
        comicId = newComicId
        currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
        updateFavoriteStatus()
        showMostRecentHistory(limit: 10, desc: "from navigateTo")
    }

    func reflectNavigationTo(newComicId: Int32) {
        // Called when the webview has navigated to a new comic, to keep track of this in the state
        let lastComicId = comicId
        comicId = newComicId
        currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
        // TODO: make a URL builder convenience Util func in a Utils file

        let backFetchRequest = createBackFetchRequest(limit: 3)
        let lastBackItems = try? context.fetch(backFetchRequest)
        if lastBackItems == nil || lastBackItems!.isEmpty || lastComicId != newComicId {
//            lastBackItems?.forEach({
//                h in
//                print("History item \(h.id) from \(h.timestamp)")
//            })
            let idItem = ComicIdHistory(context: context)
            print("Adding item with id \(newComicId) in navigation callback")
            idItem.setValue(Date(), forKey: "timestamp")
            idItem.setValue(newComicId, forKey: "id")
            try? context.save()
        } else {
            // When we navigate, depending on if we went through the UI back/forward or links in the webview, we might have already manipulated the back/forward state. So if we've already updated lastComicId, we don't need a new history state update
            // TODO: what are the UI tests I want around this?
            print("Not adding back record for \(newComicId) since lastComicId was already this")
        }
        updateFavoriteStatus()

        showMostRecentHistory(limit: 10, desc: "from reflectNavigationTo")
    }

    func metadataUpdater(alt1: String, alt2: String, alt3: String) {
        altText1 = alt1
        altText2 = alt2
        altText3 = alt3
        altTextComicId = comicId
    }

    func metadataUpToDate() -> Bool {
        return comicId == altTextComicId
    }

    func toggleFavorite() {
        let r = getFavoriteRecords()
        if r.isEmpty {
            if metadataUpToDate() {
                // TODO: disable from UI if not
                // don't let the user favorite a comic until the alt text is parsed so we save the favorite with the correct title
                let newFavorite = ComicFavorite(context: context)
                newFavorite.id = comicId
                newFavorite.timestamp = Date()
                newFavorite.title = altText3
                try? context.save()
            }
        } else {
            let oldFavorite = r.first
            if oldFavorite != nil {
                context.delete(oldFavorite!)
                try? context.save()
            }
        }
        updateFavoriteStatus()
    }

    private func updateFavoriteStatus() {
        let favoriteResult = getFavoriteRecords()
        if favoriteResult.isEmpty {
            isFavorite = false
        } else {
            isFavorite = true
        }
    }

    private func getFavoriteRecords() -> [ComicFavorite] {
        let fetchRequest: NSFetchRequest<ComicFavorite> = ComicFavorite.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: comicId))
        let r = try! context.fetch(fetchRequest)
        return r
    }

    private func refresh() {
        // We're gonna check if our backing data in CloudKit has changed 5s after app start to see if we need to update our location
        let fetchRequest = createBackFetchRequest(limit: 1)
        let lastBackItem = try? context.fetch(fetchRequest)
        let lastComicId = lastBackItem?.first?.id
        if lastComicId != nil {
            let newComicId = lastComicId!
            if comicId != newComicId {
                print("Updating current comic from refreshed state to \(newComicId) from \(comicId)")
                comicId = newComicId
                currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
            }
        }
        updateFavoriteStatus()
        showMostRecentHistory(limit: 10, desc: "from refresh")
    }

    private func createBackFetchRequest(limit: Int) -> NSFetchRequest<ComicIdHistory> {
        let backFetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
        backFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        backFetchRequest.fetchLimit = limit
        return backFetchRequest
    }

    private func showMostRecentHistory(limit: Int, desc: String) {
        let backFetchRequest = createBackFetchRequest(limit: limit)
        let lastBackItems = try? context.fetch(backFetchRequest)
        lastBackItems?.forEach {
            h in
            print("\(desc) Back item \(h.id) from \(h.timestamp)")
        }

        let forwardFetchRequest: NSFetchRequest<ComicIdForwardHistory> = ComicIdForwardHistory.fetchRequest()
        forwardFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        forwardFetchRequest.fetchLimit = limit
        let lastForwardItems = try? context.fetch(forwardFetchRequest)
        lastForwardItems?.forEach {
            h in
            print("\(desc) Forward item \(h.id) from \(h.timestamp)")
        }
    }
}
