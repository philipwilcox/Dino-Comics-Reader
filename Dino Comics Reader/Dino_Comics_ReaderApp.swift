//
//  Dino_Comics_ReaderApp.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import CoreData
import SwiftUI

@main
struct Dino_Comics_ReaderApp: App {
    let persistenceController = PersistenceController.shared

    func createViewModel() -> ComicViewModel {
        let positionFetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
        positionFetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        positionFetchRequest.fetchLimit = 1

        do {
            let lastItem = try persistenceController.container.viewContext.fetch(positionFetchRequest).first
            let comicId = Int32(lastItem?.id ?? 2801)
            let urlString = "https://qwantz.com/index.php?comic=\(comicId)"
            print("Fetched comicId \(comicId) from store from record with timestamp \(String(describing: lastItem?.timestamp))")
            let favoriteFetchRequest: NSFetchRequest<ComicFavorite> = ComicFavorite.fetchRequest()
            favoriteFetchRequest.predicate = NSPredicate(format: "id == %@", NSNumber(value: comicId))
            let favoriteResult = try persistenceController.container.viewContext.fetch(favoriteFetchRequest)
            return ComicViewModel(comicId: comicId, currentUrl: urlString, isFavorite: !favoriteResult.isEmpty, context: persistenceController.container.viewContext)
        } catch {
            print("Failed to fetch ComicIdBackHistory: \(error)")
            let comicId = Int32(2688)
            let urlString = "https://qwantz.com/index.php?comic=\(comicId)"
            return ComicViewModel(comicId: comicId, currentUrl: urlString, isFavorite: false, context: persistenceController.container.viewContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: createViewModel())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
