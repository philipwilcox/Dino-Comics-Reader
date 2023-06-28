import SwiftSoup
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var urlString: String
    
    let secretTextFetcher: (String, String, String) -> Void
    let comicIdFetcher: (Int) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.customUserAgent = "PW Annotator"
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    // TODO: reject links that aren't to other comics
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // "Debounce" so that if the url didn't change we don't refresh so that when we update the alt text state we don't reload the page and create an uncessary page view
        // Note that we store the state in the Coordinator since we can't track state (or mutate it) here
        //        print("Should I do update? urlString \(urlString) vs \(context.coordinator.lastUrl)")
        if urlString != context.coordinator.lastUrl {
            let request = URLRequest(url: URL(string: urlString)!)
            webView.load(request)
        }
        context.coordinator.lastUrl = urlString
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(secretTextFetcher: secretTextFetcher, comicIdFetcher: comicIdFetcher)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let secretTextFetcher: (String, String, String) -> Void
        let comicIdFetcher: (Int) -> Void
        var lastUrl: String
        
        init(secretTextFetcher: @escaping (String, String, String) -> Void, comicIdFetcher: @escaping (Int) -> Void) {
            self.secretTextFetcher = secretTextFetcher
            self.comicIdFetcher = comicIdFetcher
            self.lastUrl = ""
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Update both the url ID and texts in the same didFinish, vs updating URL when we start navigating, to minimize state changes
            if let url = webView.url {
                lastUrl = url.absoluteString
                let comicId = Int(URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems?.first(where: { $0.name == "comic" })!.value ?? "1")!
                comicIdFetcher(comicId)
            }
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { html, _ in
                if let html = html as? String {
                    // TODO: improve all this hideous error handling
                    let doc: Document = try! SwiftSoup.parse(html)
                    // TODO: this doesn't work for mobile html! It crashes currently!
                    let comic = try! doc.select("img.comic").first()!
                    let alt1 = try! comic.attr("title")
                    let contactString = try! doc.select("a:contains(contact)").first()!.attr("href")
                    let alt2 = URLComponents(string: contactString)!.queryItems!.first(where: { $0.name == "subject" })!.value!
                    let commentElement = try! doc.select("body").first()?.getChildNodes().first(where: { $0.nodeName() == "#comment" })! as! Comment
                    // if we ever had to find the right one from multiple comments instead of just the first, we could match on "<span class="rss-title">" in the comment
                    let alt3 = try! SwiftSoup.parse(commentElement.getData()).select("span").first()!.text()
                    
                    self.secretTextFetcher(alt1, alt2, alt3)
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                if let url = navigationAction.request.url {
                    if (url.host == "www.qwantz.com" || url.host == "qwantz.com") && url.query() != nil {
                        let pathPattern = "/index.php\\?comic=\\d+"
                        let fullPath = "\(url.path())?\(url.query()!)"
                        print(fullPath)
                        if fullPath.range(of: pathPattern, options: .regularExpression, range: nil, locale: nil) != nil {
                            decisionHandler(.allow)
                        } else {
                            print("No match")
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            decisionHandler(.cancel)
                        }
                    } else {
                        //                        print("would open browser for non-comic link")
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        decisionHandler(.cancel)
                    }
                } else {
                    // TODO: wtf kinda case would be this? but don't interfere I guess...
                    decisionHandler(.allow)
                }
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
