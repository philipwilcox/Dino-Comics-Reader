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

    var body: some View {
        HStack {
            Text(String(id))
            Spacer()
            Text(title)
            // TODO: add delete button
        }
    }
}

struct FavoritesView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: FavoritesViewModel

    var body: some View {
        List(viewModel.favorites, id: \.id) { favorite in
            FavoriteRow(id: favorite.id, title: favorite.title ?? "[NONE]")
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = FavoritesViewModel(context: PersistenceController.preview.container.viewContext)
        FavoritesView(viewModel: viewModel).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
