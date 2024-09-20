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
    @StateObject private var viewModel = LinkedInViewModel()
    @State private var showingWebView = false
    @State private var authorizationUrlRequest: URLRequest?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            if viewModel.accessToken.isEmpty {
                Button("Login with LinkedIn") {
                    authorizationUrlRequest = viewModel.startAuthorizationFlow()
                    showingWebView = true
                }
            } else {
                Text("Logged in with LinkedIn!")
                Button("Fetch Email") {
                    viewModel.fetchEmailAddress()
                }
                Button("Post to LinkedIn") {
                    viewModel.postContentToLinkedIn(message: "Hello LinkedIn from my iOS App!")
                }
            }
        }
        .sheet(isPresented: $showingWebView, onDismiss: {
            if viewModel.isLoggedIn {
                // Do something if needed after the WebView is closed
            }
        }) {
            if let request = authorizationUrlRequest {
                ZStack {
                    WebView(urlRequest: request, viewModel: viewModel, isLoading: $isLoading)
                    if isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
        }
        .onChange(of: viewModel.isLoggedIn) { isLoggedIn in
            if isLoggedIn {
                showingWebView = false // Automatically close WebView when logged in
            }
        }
    }
}

// WebView for LinkedIn Login
struct WebView: UIViewRepresentable {
    let urlRequest: URLRequest
    @ObservedObject var viewModel: LinkedInViewModel
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
        
        // Show the loading indicator when the page starts loading
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        // Hide the loading indicator when the page finishes loading
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        // Intercept the custom URL scheme
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                // Check if it's a custom scheme (like sociallinkup://)
                if url.scheme == "sociallinkup" {
                    // Handle custom URL schemes here
                    if url.host == "auth", url.path == "/linkedin" {
                        let code = getAuthorizationCode(from: url)
                        let state = getState(from: url)
                        
                        // Validate the state and process the authorization code
                        if let code = code, let state = state {
                            if state == parent.viewModel.state {
                                // Exchange the authorization code for access token
                                parent.viewModel.exchangeAuthorizationCodeForAccessToken(code: code)
                                
                                // Automatically dismiss the WebView after successful login
                                parent.viewModel.isLoggedIn = true
                            } else {
                                print("State mismatch!")
                            }
                        }
                    }
                    // Prevent WebView from trying to load the custom scheme
                    decisionHandler(.cancel)
                    return
                }
            }
            // Otherwise, allow the WebView to proceed with the URL
            decisionHandler(.allow)
        }
        
        private func getAuthorizationCode(from url: URL) -> String? {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                return code
            }
            return nil
        }
        
        private func getState(from url: URL) -> String? {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let state = components.queryItems?.first(where: { $0.name == "state" })?.value {
                return state
            }
            return nil
        }
    }
}

#Preview {
    LinkedInLoginView()
//        .environmentObject(LinkedInAuth())
}
