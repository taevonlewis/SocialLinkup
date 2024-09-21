//
//  Twitter.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import SwiftUI
import AuthenticationServices

import SwiftUI

struct TwitterView: View {
    @StateObject private var viewModel = TwitterViewModel()
    @State private var twitterIsLoading = false
    @State private var tweetText = ""

    var body: some View {
        VStack {
            if !viewModel.isLoggedIn {
                Button("Login with Twitter") {
                    twitterIsLoading = true
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        viewModel.startAuthentication(presentationAnchor: window)
                    }
                }
            } else {
                Text("Logged in!")
                TextField("Enter your tweet", text: $tweetText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Post Tweet") {
                    viewModel.postTweet(tweetText: tweetText)
                }
                .onAppear {
                    if twitterIsLoading {
                        twitterIsLoading = false
                    }
                }
            }

            if twitterIsLoading {
                ProgressView("Loading...")
            }
        }
        .padding()
    }
}
#Preview {
    TwitterView()
}
