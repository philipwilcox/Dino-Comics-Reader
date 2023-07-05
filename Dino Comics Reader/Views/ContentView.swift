//
//  ContentView.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import CoreData
import SwiftUI

struct ComicIdFieldView: View {
    @Binding var comicId: Int32
    @Binding var isFavorite: Bool
    let completionCallback: (Int32) -> Void
    let clickCallback: () -> Void

    var body: some View {
        TextField("Comic", value: $comicId, formatter: NumberFormatter())
            .keyboardType(.numbersAndPunctuation).onSubmit {
                completionCallback(comicId)
            }
            .frame(width: 42)
        Button(action: clickCallback) {
            Image(systemName: "star.fill")
                .foregroundColor(isFavorite ? .yellow : .gray)
                .frame(alignment: .leading)
        }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: ComicViewModel

    var body: some View {
        VStack {
            // TODO: put URL on a top row on phone layouts
            // TODO: add a "view favorites" button
            HStack {
                Text(viewModel.currentUrl).padding(.leading).frame(alignment: .leading).textSelection(.enabled)
                Spacer()
                ComicIdFieldView(comicId: $viewModel.comicId, isFavorite: $viewModel.isFavorite, completionCallback: viewModel.navigateTo, clickCallback: viewModel.toggleFavorite)
                // TODO: there's some sort of contraint violation here, learn to debug
                Button(action: viewModel.navigateBack, label: { Text("Back") })
                Button(action: viewModel.navigateForward, label: { Text("Forward") })
            }
            WebView(urlString: $viewModel.currentUrl,
                    secretTextFetcher: viewModel.metadataUpdater,
                    comicIdFetcher: viewModel.reflectNavigationTo)
            VStack {
                Text(viewModel.altText1).font(.caption2).foregroundColor(Color(red: 1, green: 0.4, blue: 0)).multilineTextAlignment(.center).textSelection(.enabled)
                Text(viewModel.altText2).font(.caption2).foregroundColor(Color(red: 1, green: 0.7, blue: 0)).multilineTextAlignment(.center).textSelection(.enabled)
                Text(viewModel.altText3).font(.caption2).foregroundColor(Color(red: 0.7, green: 0.4, blue: 0)).multilineTextAlignment(.center).textSelection(.enabled)
            }
        }.onAppear(perform: {
            print("done with onAppear, will load \(viewModel.currentUrl)")

        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ComicViewModel(context: PersistenceController.preview.container.viewContext)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
