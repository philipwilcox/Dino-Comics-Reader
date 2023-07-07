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
            Text(String(id)).foregroundColor(.black)
            Text(title)
            Spacer()
            Button(action: deleteCallback) {
                Image(systemName: "minus.circle").foregroundColor(.red).padding(.leading, 2)
            }.buttonStyle(BorderlessButtonStyle())
        }
    }
}

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: FavoritesViewModel
    let navigationCallback: (Int32) -> Void
    @Binding var currentComicId: Int32
    @Binding var currentIsFavorited: Bool

    var body: some View {
        VStack {
            List(viewModel.favorites, id: \.id) { favorite in
                Button(action: {
                    self.navigationCallback(favorite.id)
                    dismiss()
                }) {
                    FavoriteRow(id: favorite.id, title: favorite.title ?? "[NONE]", deleteCallback: {
                        if currentIsFavorited, favorite.id == currentComicId {
                            currentIsFavorited = false
                        }
                        // the data for favorite.id will only be usable for the equality check BEFORE we delete the favorite!
                        viewModel.deleteFavorite(favorite: favorite)
                    })
                }
            }
        }.navigationTitle("Favorites")
    }
}

struct FavoritesView_Previews: PreviewProvider {
    @State static var currentIsFavorite = false
    @State static var currentComicId = Int32(2400)

    static var previews: some View {
        let viewModel = FavoritesViewModel(context: PersistenceController.preview.container.viewContext)
        FavoritesView(viewModel: viewModel, navigationCallback: { _ in }, currentComicId: $currentComicId, currentIsFavorited: $currentIsFavorite).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
