//
//  FavoritesView.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 7/5/23.
//

import SwiftUI

struct FavoriteRow: View {
    var id: Int32
    var title: String
    var deleteCallback: () -> Void

    var body: some View {
        HStack {
            Text(String(id))
            Spacer()
            Text(title)
            Button(action: deleteCallback) {
                Image(systemName: "minus.circle").foregroundColor(.red).padding(.leading, 2)
            }
        }
    }
}

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        VStack {
            List(viewModel.favorites, id: \.id) { favorite in
                FavoriteRow(id: favorite.id, title: favorite.title ?? "[NONE]", deleteCallback: {
                    viewModel.deleteFavorite(favorite: favorite)
                })
            }
        }.navigationTitle("Favorites")
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FavoritesViewModel(context: PersistenceController.preview.container.viewContext)
        FavoritesView(viewModel: viewModel).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
