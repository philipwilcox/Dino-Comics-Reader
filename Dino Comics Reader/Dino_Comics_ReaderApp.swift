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
        let fetchRequest: NSFetchRequest<ComicIdHistory> = ComicIdHistory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let lastItem = try persistenceController.container.viewContext.fetch(fetchRequest).first
            let comicId = Int(lastItem?.id ?? 2801)
            let urlString = "https://qwantz.com/index.php?comic=\(comicId)"
            print("Fetched comicId \(comicId) from store from record with timestamp \(String(describing: lastItem?.timestamp))")
            return ComicViewModel(comicId: comicId, currentUrl: urlString, context: persistenceController.container.viewContext)
        } catch {
            print("Failed to fetch ComicIdBackHistory: \(error)")
            let comicId = 2688
            let urlString = "https://qwantz.com/index.php?comic=\(comicId)"
            return ComicViewModel(comicId: comicId, currentUrl: urlString, context: persistenceController.container.viewContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: createViewModel())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
