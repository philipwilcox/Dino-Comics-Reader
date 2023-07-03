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

    private var context: NSManagedObjectContext

    private var timer: Timer?

    init(comicId: Int, currentUrl: String, context: NSManagedObjectContext) {
        self.comicId = comicId
        self.currentUrl = currentUrl
        self.context = context

        // TODO: set a second periodic timer? And for that one add an invalidation stopTimer() method that the View can hook into if it goes away
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { _ in
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

                comicId = Int(lastItem.id)
                currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"

                context.delete(currentItem)
                try context.save()
                print("Saving context navigating back to \(comicId)")
            }
        } catch {
            print("Failed to fetch ComicIdBackHistory: \(error)")
        }
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

                comicId = Int(nextItem.id)
                currentUrl = "https://qwantz.com/index.php?comic=\(comicId)"

                // Delete the next item from the forward history
                context.delete(nextItem)
                try context.save()
            }
        } catch {
            print("Failed to fetch ComicIdForwardHistory: \(error)")
        }
        showMostRecentHistory(limit: 10, desc: "from navigateForward")
    }

    func navigateTo(newComicId: Int) {
        let idItem = ComicIdHistory(context: context)
        print("Adding item with id \(newComicId) in webview completion callback")
        idItem.setValue(newComicId, forKey: "id")
        idItem.setValue(Date(), forKey: "timestamp")
        try? context.save()
        comicId = newComicId
        currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
        showMostRecentHistory(limit: 10, desc: "from navigateTo")
    }

    func reflectNavigationTo(newComicId: Int) {
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
            // TODO: think more about how that link between history state and back/forward works in a world with cloudkit and all too...
            // TODO: why not let THIS always be what maintains our back-state-adding?
            // TODO: what are the UI tests I want around this?
            // TODO: does pushing back/forward too fast before this is run cause issues? should I update history EARLIER on URL load?
            print("Not adding back record for \(newComicId) since lastComicId was already this")
        }
        
        showMostRecentHistory(limit: 10, desc: "from reflectNavigationTo")
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
        lastBackItems?.forEach({
            h in
            print("\(desc) Back item \(h.id) from \(h.timestamp)")
        })
        
        let forwardFetchRequest: NSFetchRequest<ComicIdForwardHistory> = ComicIdForwardHistory.fetchRequest()
        forwardFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        forwardFetchRequest.fetchLimit = limit
        let lastForwardItems = try? context.fetch(forwardFetchRequest)
        lastForwardItems?.forEach({
            h in
            print("\(desc) Forward item \(h.id) from \(h.timestamp)")
        })
    }

    func refresh() {
        // We're gonna check if our backing data in CloudKit has changed 5s after app start to see if we need to update our location
        let fetchRequest = createBackFetchRequest(limit: 1)
        let lastBackItem = try? context.fetch(fetchRequest)
        let lastComicId = lastBackItem?.first?.id
        if lastComicId != nil {
            // Any way to improve int32 vs int coercion here?
            let newComicId = Int(lastComicId!)
            if comicId != newComicId {
                print("Updating current comic from refreshed state to \(newComicId) from \(comicId)")
                comicId = newComicId
                currentUrl = "https://qwantz.com/index.php?comic=\(newComicId)"
            }
        }
        showMostRecentHistory(limit: 10, desc: "from refresh")
    }
}
