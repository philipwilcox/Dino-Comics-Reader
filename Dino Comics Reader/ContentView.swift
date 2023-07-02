//
//  ContentView.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import CoreData
import SwiftUI

struct ComicIdFieldView: View {
    @Binding var comicId: Int
    let completionCallback: (Int) -> Void

    var body: some View {
        TextField("Comic", value: $comicId, formatter: NumberFormatter())
            .keyboardType(.numbersAndPunctuation).onSubmit {
                completionCallback(comicId)
            }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var viewModel: ComicViewModel

    @State var secret1 = ""
    @State var secret2 = ""
    @State var secret3 = ""

    var body: some View {
        VStack {
            HStack {
                Text(viewModel.currentUrl).padding(.leading).frame(alignment: .leading).textSelection(.enabled)
                Spacer()
                ComicIdFieldView(comicId: $viewModel.comicId, completionCallback: viewModel.navigateTo)
                    .frame(width: 60)
                // TODO: there's some sort of contraint violation here, learn to debug
                Button(action: viewModel.navigateBack, label: { Text("Back") })
                Button(action: viewModel.navigateForward, label: { Text("Forward") })
            }
            WebView(urlString: $viewModel.currentUrl,
                    secretTextFetcher: {
                        text1, text2, text3 in
                        secret1 = text1
                        secret2 = text2
                        secret3 = text3
                    },
                    comicIdFetcher: viewModel.reflectNavigationTo)
            VStack {
                Text(secret1).font(.caption2).foregroundColor(Color(red: 1, green: 0.4, blue: 0)).multilineTextAlignment(.center).textSelection(.enabled)
                Text(secret2).font(.caption2).foregroundColor(Color(red: 1, green: 0.7, blue: 0)).multilineTextAlignment(.center).textSelection(.enabled)
                Text(secret3).font(.caption2).foregroundColor(Color(red: 0.7, green: 0.4, blue: 0)).multilineTextAlignment(.center).textSelection(.enabled)
            }
        }.onAppear(perform: {
            print("done with onAppear, will load \(viewModel.currentUrl)")

        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ComicViewModel(comicId: 2688, currentUrl: "https://qwantz.com/index.php?comic=2600", context: PersistenceController.preview.container.viewContext)).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
