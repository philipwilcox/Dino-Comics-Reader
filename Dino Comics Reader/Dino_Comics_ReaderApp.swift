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
        return ComicViewModel(context: persistenceController.container.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: createViewModel())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
