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

// TODO: build a back button/forward button
// TODO: track history (last N?)


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicIdHistory.timestamp, ascending: true)],
        animation: .default)
    private var backItems: FetchedResults<ComicIdHistory>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ComicIdForwardHistory.timestamp, ascending: true)],
        animation: .default)
    private var forwardItems: FetchedResults<ComicIdForwardHistory>
    // TODO: how should I really do a navigation stack?

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
                    let idItem = ComicIdHistory(context: viewContext)
                    idItem.setValue(id, forKey: "id")
                    idItem.setValue(Date(), forKey: "timestamp")
                    try? self.viewContext.save()
                    urlString = "https://qwantz.com/index.php?comic=\(id)"
                })
                .frame(width: 55).padding(.trailing)
                // TODO: the frame constraints around this are conflicting and need debugging when I click into it
                Button(action: {
                    // TODO: disable if items is empty?
                    let nextItem = backItems[1]
                    let lastItem = backItems[0]
                    let forwardItem = ComicIdForwardHistory(context: viewContext)
                    forwardItem.setValue(lastItem.id, forKey: "id")
                    forwardItem.setValue(Date(), forKey: "timestamp")
                    viewContext.delete(lastItem)
                    try? viewContext.save()
                    // TODO: make a helper for updating these two state vars? or make urlstring computed again?
                    comicId = nextItem.value(forKey: "id") as! Int
                    urlString = "https://qwantz.com/index.php?comic=\(comicId)"
                }, label: { Text("Back") })
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
                comicId = id
                urlString = "https://qwantz.com/index.php?comic=\(id)"
                let idItem = ComicIdHistory(context: viewContext)
                idItem.setValue(Date(), forKey: "timestamp")
                idItem.setValue(id, forKey: "id")
                try? self.viewContext.save()
            })
            VStack {
                Text(secret1).font(.caption).foregroundColor(Color(red: 1, green: 0.4, blue: 0))
                Text(secret2).font(.caption2).foregroundColor(Color(red: 1, green: 0.7, blue: 0))
                Text(secret3).font(.caption).foregroundColor(Color(red: 0.7, green: 0.4, blue: 0))
            }
        }.onAppear(perform: {
            // TODO: move this to a named method for readability
            // TODO: delete any backItems and forwardItems without timestamps
            // TODO: make this all optional for init / add a "debug panel"?
//            let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: "ComicIdHistory")
//            let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
//            let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "ComicIdForwardHistory")
//            let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)
//            do {
//                try viewContext.execute(deleteRequest1)
//                try viewContext.execute(deleteRequest2)
//            } catch _ as NSError {
//                // TODO: handle the error
//            }
            comicId = backItems.isEmpty ? 2487 : backItems.first!.value(forKey: "id")! as! Int
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
