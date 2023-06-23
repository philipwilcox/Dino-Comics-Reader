//
//  ContentView.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/21/23.
//

import SwiftUI
import CoreData

struct ComicIdFieldView: View {
    @Binding var comicId: Int
    let completionCallback: (Int) -> Void
    
    var body : some View {
        TextField("Comic", value: $comicId, formatter: NumberFormatter())
            .keyboardType(.numberPad).onSubmit {
                completionCallback(comicId)
            }
    }
}


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicId.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<ComicId>

    @State var secret1 = ""
    @State var secret2 = ""
    @State var secret3 = ""
    @State var comicId = 1
    @State var urlString = ""
    
    
    var body: some View {
        VStack() {
//            let _ = {
//                print(displayComicId)
//                print(urlString)
//            }()
            // TODO: sync to cloud
            HStack{
                Text(urlString).padding(.leading).frame(maxWidth: .infinity, alignment: .leading).padding(.leading)
                // TODO: add a "goto" button
                ComicIdFieldView(comicId: $comicId, completionCallback: {
                    id in
                    if (items.isEmpty) {
                        let idItem = ComicId(context: viewContext)
                        idItem.setValue(id, forKey: "id")
                    } else {
                        let item = items.first
                        item!.setValue(id, forKey: "id")
                    }
                    try? self.viewContext.save()
                    urlString = "https://qwantz.com/index.php?comic=\(id)"
                })
                .frame(width: 55).padding(.trailing)
                // TODO: the frame constraints around this are conflicting and need debugging
            }
            WebView(urlString: $urlString,
            secretTextFetcher: {
                text1, text2, text3 in
                secret1 = text1
                secret2 = text2
                secret3 = text3
            },
                comicIdFetcher: {
                // TODO: this is running a few times per navigation since we extract the alt text AFTER The first refresh, we should redo that with bindings or such...
                id in
                comicId = id
                urlString = "https://qwantz.com/index.php?comic=\(id)"
                if (items.isEmpty) {
                    let idItem = ComicId(context: viewContext)
                    idItem.setValue(id, forKey: "id")
                } else {
                    let item = items.first
                    item!.setValue(id, forKey: "id")
                }
                try? self.viewContext.save()
            })
            VStack {
                Text(secret1).font(.caption).foregroundColor(Color(red: 1, green: 0.4, blue: 0))
                Text(secret2).font(.caption2).foregroundColor(Color(red: 1, green: 0.7, blue: 0))
                Text(secret3).font(.caption).foregroundColor(Color(red: 0.7, green: 0.4, blue: 0))
            }
        }.onAppear(perform: {
            // TODO: move this to a named method for readability
            comicId = items.isEmpty ? 2487 : items.first!.value(forKey: "id")! as! Int
            print(comicId)
            urlString =  "https://qwantz.com/index.php?comic=\(comicId)"
            print("done with onAppear")
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
