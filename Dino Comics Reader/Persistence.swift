//
//  Persistence.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        // TODO: set up some mock comics data for preview?
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newItem = ComicIdHistory(context: viewContext)
        newItem.timestamp = Date()
        newItem.id = 2500
        let newItem2 = ComicIdForwardHistory(context: viewContext)
        newItem2.timestamp = Date()
        newItem2.id = 2501
        try! viewContext.save()
//        for _ in 0..<10 {
//            let newItem = ComicIdHistory(context: viewContext)
//            newItem.timestamp = Date()
//        }
//        do {
//            try viewContext.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nsError = error as NSError
//            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
//        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Dino_Comics_Reader")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            print("HI LOADED STORES")
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        let description = container.persistentStoreDescriptions.first
        let remoteChangeKey = "NSPersistentStoreRemoteChangeNotificationOptionKey"
        description?.setOption(true as NSNumber,
                               forKey: remoteChangeKey)

        // TODO: this doesn't work
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { notification in
                // TODO: make this thread safe, move to a class, look at example code of how this is usually used
                print(notification)
//                self.processRemoteStoreChange(notification)
            }
    }
    
}
