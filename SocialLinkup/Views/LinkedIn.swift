//
//  LinkedIn.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import SwiftUI
import SwiftData
import WebKit

struct LinkedInLoginView: View {
    @StateObject private var linkedinViewModel = LinkedInViewModel()
    @State private var showingWebView = false
    @State private var authorizationUrlRequest: URLRequest?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if linkedinViewModel.accessToken.isEmpty {
                Button("Login with LinkedIn") {
                    authorizationUrlRequest = linkedinViewModel.startAuthorizationFlow()
                    showingWebView = true
                }
            } else {
                Text("Logged in with LinkedIn!")
                Button("Fetch Email") {
                    linkedinViewModel.fetchEmailAddress()
                }
                Button("Post to LinkedIn") {
                    linkedinViewModel.postContentToLinkedIn(message: "Hello LinkedIn from my iOS App!")
                }
            }
        }
        .sheet(isPresented: $showingWebView, onDismiss: {
            if linkedinViewModel.isLoggedIn {
                // Do something if needed after the WebView is closed
            }
        }) {
            if let request = authorizationUrlRequest {
                ZStack {
                    WebView(urlRequest: request, viewModel: linkedinViewModel, isLoading: $isLoading)
                    if isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
        }
        .onChange(of: linkedinViewModel.isLoggedIn) { oldValue, newValue in
            if newValue {
                showingWebView = false
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlRequest: URLRequest
    var viewModel: any OAuthViewModelProtocol
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(urlRequest)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                if url.scheme == "sociallinkup" {
                    parent.viewModel.handleCallbackURL(url)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

protocol OAuthViewModelProtocol: ObservableObject {
    func handleCallbackURL(_ url: URL)
}

#Preview {
    LinkedInLoginView()
}
