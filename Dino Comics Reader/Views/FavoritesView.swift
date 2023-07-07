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

    var body: some View {
        VStack {
            List(viewModel.favorites, id: \.id) { favorite in
                Button(action: {
                    self.navigationCallback(favorite.id)
                    dismiss()
                }) {
                    FavoriteRow(id: favorite.id, title: favorite.title ?? "[NONE]", deleteCallback: {
                        viewModel.deleteFavorite(favorite: favorite)
                    })
                }
            }
        }.navigationTitle("Favorites")
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FavoritesViewModel(context: PersistenceController.preview.container.viewContext)
        FavoritesView(viewModel: viewModel, navigationCallback: { _ in }).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
