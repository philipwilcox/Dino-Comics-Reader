//
//  Dino_Comics_ReaderApp.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import SwiftUI

@main
struct Dino_Comics_ReaderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
