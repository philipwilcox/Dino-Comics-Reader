//
//  WebView.swift
//  Dino Comics Reader
//
//  Created by Philip Wilcox on 6/22/23.
//

import Foundation

import SwiftUI
import WebKit
import SwiftSoup

// See https://sarunw.com/posts/swiftui-webview/
// And https://developer.apple.com/documentation/swiftui/uiviewrepresentable


struct WebView: UIViewRepresentable {
    let request: URLRequest
    
    let webView: WKWebView
    
    

    // 2
    func makeUIView(context: Context) -> WKWebView {
        webView.customUserAgent = "PW Annotator"
        return webView
    }

    // 3
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("HI")
        webView.load(request)
    }
}


// see https://stackoverflow.com/a/68671543
class MyWKDelegate: NSObject, WKNavigationDelegate{
    
    var secretTextFetcher: ((String, String, String) -> Void)?
    
    override init() {
    }
    
    func setCallback(callback: @escaping (String, String, String) -> Void) {
        secretTextFetcher = callback
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("End loading")
        webView.evaluateJavaScript("document.body.innerHTML", completionHandler: { result, error in
            
            if let html = result as? String {
                // TODO: improve all this hideous error handling
                let doc: Document = try! SwiftSoup.parse(html)
                
                let comic = try! doc.select("img.comic").first()!
                let alt1 = try! comic.attr("title")
                
                self.secretTextFetcher!(alt1, "THIS", "COOL")
//                        print(html)
                }
            })
    }
    
    // TODO: consolidate this didFinish/didCommit stuff?
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("Start loading")
        webView.evaluateJavaScript("document.body.innerHTML", completionHandler: { result, error in
            
            if let html = result as? String {
                // TODO: improve all this hideous error handling
                let doc: Document = try! SwiftSoup.parse(html)
                
                let comic = try! doc.select("img.comic").first()!
                let alt1 = try! comic.attr("title")
                
                self.secretTextFetcher!(alt1, "THIS", "COOL")
//                        print(html)
                }
            })
    }
}

struct WebViewWrapper: View {
    // 1
    let url: URL
    let secretTextFetcher: (String, String, String) -> Void
    let navDelegate: MyWKDelegate
    let webView: WebView
    
    init(url: URL, secretTextFetcher: @escaping (String, String, String) -> Void) {
        self.url = url
        self.secretTextFetcher = secretTextFetcher
        self.navDelegate = MyWKDelegate()
        self.navDelegate.setCallback(callback: secretTextFetcher)
        let wkView = WKWebView()
        wkView.navigationDelegate = self.navDelegate
        let request = URLRequest(url: url)
        self.webView = WebView(request: request, webView: wkView)
    }
    
    var body : some View {
        self.webView
    }
}
