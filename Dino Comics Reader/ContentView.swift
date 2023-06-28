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
            .keyboardType(.numberPad).onSubmit {
                completionCallback(comicId)
            }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicIdHistory.timestamp, ascending: false)],
        animation: .default)
    private var backItems: FetchedResults<ComicIdHistory>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicIdForwardHistory.timestamp, ascending: false)],
        animation: .default)
    private var forwardItems: FetchedResults<ComicIdForwardHistory>
    // TODO: how should I really do a navigation stack?

    @State var secret1 = ""
    @State var secret2 = ""
    @State var secret3 = ""
    @State var comicId = 1
    @State var urlString = ""

    var body: some View {
        VStack {
            //            let _ = {
            //                print(displayComicId)
            //                print(urlString)
            //            }()
            // TODO: sync to cloud
            HStack {
                Text(urlString).padding(.leading).frame(alignment: .leading).textSelection(.enabled)
                Spacer()
                ComicIdFieldView(comicId: $comicId, completionCallback: {
                    id in
                    let idItem = ComicIdHistory(context: viewContext)
                    print("Adding item with id \(id) in webview completion callback")
                    idItem.setValue(id, forKey: "id")
                    idItem.setValue(Date(), forKey: "timestamp")
                    try? self.viewContext.save()
                    urlString = "https://qwantz.com/index.php?comic=\(id)"
                })
                .frame(width: 60)
                // TODO: there's some sort of contraint violation here, learn to debug
                Button(action: {
                    // TODO: disable if items has less than length 2
                    let lastItem = backItems[0]
                    let lastId = lastItem.value(forKey: "id")
                    print("last item id is \(String(describing: lastId)) vs comic ID which is \(comicId)")
                    assert(lastItem.value(forKey: "id") as! Int == comicId)
                    let nextItem = backItems[1]
                    //                    print("Got last two items from back history: \(String(describing: lastItem.value(forKey: "id"))), \(String(describing: nextItem.value(forKey: "id")))")
                    let forwardItem = ComicIdForwardHistory(context: viewContext)
                    forwardItem.setValue(lastItem.value(forKey: "id"), forKey: "id")
                    forwardItem.setValue(Date(), forKey: "timestamp")
                    viewContext.delete(lastItem)
                    try? viewContext.save()
                    // TODO: make a helper for updating these two state vars? or make urlstring computed again?
                    comicId = nextItem.value(forKey: "id") as! Int
                    urlString = "https://qwantz.com/index.php?comic=\(comicId)"
                    print("Will go back to \(urlString), comicId now = \(comicId)")
                    //                    print("Added forward item for \(String(describing: forwardItem.value(forKey: "id")))")

                }, label: { Text("Back") })
                Button(action: {
                    // TODO: disable if forwarditems is empty?
                    let lastItem = backItems[0]
                    let lastId = lastItem.value(forKey: "id")
                    assert(lastId as! Int == comicId)
                    let nextItem = forwardItems[0]
                    let nextId = nextItem.value(forKey: "id") as! Int
                    viewContext.delete(nextItem)
                    // TODO: make a helper for updating these two state vars? or make urlstring computed again?
                    comicId = nextId
                    // we need to add a new back record since we're updating comicId, we rely on "top of back stack" = "current comic ID" assumption elsewhere
                    // TODO: clean this assumption up, make better state management controls for this...
                    let backItem = ComicIdHistory(context: viewContext)
                    backItem.setValuesForKeys(["id": nextId, "timestamp": Date()])
                    try? viewContext.save()
                    urlString = "https://qwantz.com/index.php?comic=\(comicId)"
                    print("Will go forward to \(urlString), comicId now = \(comicId)")

                }, label: { Text("Forward") })
            }
            WebView(urlString: $urlString,
                    secretTextFetcher: {
                        text1, text2, text3 in
                        secret1 = text1
                        secret2 = text2
                        secret3 = text3
                    },
                    comicIdFetcher: {
                        id in
                        let lastComicId = comicId
                        comicId = id
                        urlString = "https://qwantz.com/index.php?comic=\(id)"
                        if lastComicId != id || backItems.isEmpty {
                            // this way we don't add a history item on a refresh or initial app load from a history state
                            let idItem = ComicIdHistory(context: viewContext)
                            print("Adding item with id \(id) in navigation callback")
                            idItem.setValue(Date(), forKey: "timestamp")
                            idItem.setValue(id, forKey: "id")
                            try? self.viewContext.save()
                        } else {
                            print("Not adding back record for \(id) since lastComicId was already this")
                        }
                    })
            VStack {
                Text(secret1).font(.caption2).foregroundColor(Color(red: 1, green: 0.4, blue: 0)).multilineTextAlignment(.center)
                Text(secret2).font(.caption2).foregroundColor(Color(red: 1, green: 0.7, blue: 0)).multilineTextAlignment(.center)
                Text(secret3).font(.caption2).foregroundColor(Color(red: 0.7, green: 0.4, blue: 0)).multilineTextAlignment(.center)
            }
        }.onAppear(perform: {
            // TODO: move this to a named method for readability
            backItems.forEach { item in
                // TODO: get rid of this cleanup stuff when we don't need it anymore
                if item.value(forKey: "timestamp") == nil {
                    viewContext.delete(item)
                }
            }
            forwardItems.forEach { item in
                if item.value(forKey: "timestamp") == nil {
                    viewContext.delete(item)
                }
            }
            try! viewContext.save()
            // TODO: how do I force-refresh my other items query to reflect these changes?
            print("We have \(backItems.count) items in back stack; \(forwardItems.count) in forward stack")
            comicId = backItems.isEmpty ? 2522 : backItems.first!.value(forKey: "id")! as! Int
            urlString = "https://qwantz.com/index.php?comic=\(comicId)"
            print("done with onAppear, will load \(urlString)")
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    // TODO: if i don't create both a back and forward history item in the preview persistence env this fails on "Fetch request must have an entity"
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
