//
//  FavoritesViewModel.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 7/5/23.
//

import CoreData
import Foundation

class FavoritesViewModel: ObservableObject {
    @Published var favorites: [ComicFavorite]
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        
        let fetchRequest: NSFetchRequest<ComicFavorite> = ComicFavorite.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let newFavorites = try? context.fetch(fetchRequest)
        self.favorites = newFavorites ?? []
    }
    
    func deleteFavorite(favorite: ComicFavorite) {
        context.delete(favorite)
        try? context.save()
        // TODO: paginate this eventually, but it's gonna be <thousands, so... no big deal
        let fetchRequest: NSFetchRequest<ComicFavorite> = ComicFavorite.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let newFavorites = try? context.fetch(fetchRequest)
        favorites = newFavorites ?? favorites
    }
}
