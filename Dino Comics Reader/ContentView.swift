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
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @State var secret1 = ""
    @State var secret2 = ""
    @State var secret3 = ""
    var body: some View {
        VStack {
            Text("Something New")
                .font(.title)
            let url = URL(string: "https://www.qwantz.com")!
            WebView(url: url,
            secretTextFetcher: {
                text1, text2, text3 in
                secret1 = text1
                secret2 = text2
                secret3 = text3
            })
            Text(secret1)
            Text(secret2)
            Text(secret3)
        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
