//
//  ContentView.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicId.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<ComicId>

    @State var secret1 = ""
    @State var secret2 = ""
    @State var secret3 = ""
    
    var body: some View {
        VStack {
            Text("Something New")
                .font(.title)
            // TODO: add a "goto" button; start from at least 2487 for my manual init
            // TODO: sync to cloud
            let comicId = items.isEmpty ? 1 : items.first!.value(forKey: "id")!
            let urlString = "https://qwantz.com/index.php?comic=\(comicId)"
            let url = URL(string: urlString)!
            WebView(url: url,
            secretTextFetcher: {
                text1, text2, text3 in
                secret1 = text1
                secret2 = text2
                secret3 = text3
            },
                comicIdFetcher: {
                id in
                print(id)
                if (items.isEmpty) {
                    let idItem = ComicId(context: viewContext)
                    idItem.setValue(id, forKey: "id")
                } else {
                    let item = items.first
                    item!.setValue(id, forKey: "id")
                }
                try? self.viewContext.save()
            })
            Text(secret1).font(.caption)
            Text(secret2).font(.caption2)
            Text(secret3).font(.caption)
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
