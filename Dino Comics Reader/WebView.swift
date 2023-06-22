import SwiftUI
import WebKit
import SwiftSoup

struct WebView: UIViewRepresentable {
    let url: URL
    
    let secretTextFetcher: (String, String, String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.customUserAgent = "PW Annotator"
        webView.navigationDelegate = context.coordinator
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // TODO: this update is called again after the text is applied at the outer layer I guess cause of reflow?
        // TODO: investigate if there's a graceful improvement, or if it's just totally unecessary
//        let request = URLRequest(url: url)
//        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(secretTextFetcher: secretTextFetcher)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let secretTextFetcher: (String, String, String) -> Void
        
        init(secretTextFetcher: @escaping (String, String, String) -> Void) {
            self.secretTextFetcher = secretTextFetcher
        }
        
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { html, error in
                if let html = html as? String {
                    // TODO: improve all this hideous error handling
                    let doc: Document = try! SwiftSoup.parse(html)

                    let comic = try! doc.select("img.comic").first()!
                    let alt1 = try! comic.attr("title")
                    let contactQueryString = try! doc.select("a:contains(contact)").first()!.attr("href").split(separator: "?", maxSplits: 1, omittingEmptySubsequences: true)[1]
                    let contactString = try! doc.select("a:contains(contact)").first()!.attr("href")
                    let alt2 = URLComponents(string: contactString)!.queryItems!.first(where: { $0.name == "subject" })!.value!
                    print(alt2)
                    let commentElement = try! doc.select("body").first()?.getChildNodes().first(where: { $0.nodeName() == "#comment" })! as! Comment
                    // if we ever had to find the right one from multiple comments instead of just the first, we could match on "<span class="rss-title">" in the comment
                    let alt3 = try! SwiftSoup.parse(commentElement.getData()).select("span").first()!.text()
                    
                    self.secretTextFetcher(alt1, alt2, alt3)
                    }
            }
        }
    }
}
