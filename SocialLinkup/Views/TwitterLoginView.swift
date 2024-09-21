//
//  Twitter.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import SwiftUI
import AuthenticationServices

struct TwitterLoginView: View {
    @StateObject private var twitterViewModel = TwitterViewModel()
    @State private var twitterIsLoading = false
    @State private var tweetText = ""

    var body: some View {
        VStack(spacing: 15) {
            LoadingView(isLoading: twitterIsLoading, loadingText: "Logging into Twitter...")

            if !twitterViewModel.isLoggedIn && !twitterIsLoading {
                Button(action: {
                    twitterIsLoading = true
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        twitterViewModel.startTwitterAuthentication(presentationAnchor: window)
                    }
                }) {
                    Image("Twitter-Gray-Sign-In")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 50)
                }
            } else if twitterViewModel.isLoggedIn {
                Text("Twitter: @\(twitterViewModel.username)")
                    .font(.headline)

                TextField("Enter your tweet", text: $tweetText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                Button("Post Tweet") {
                    twitterViewModel.postTwitterTweet(tweetText: tweetText)
                }
                .padding(.top)
                .onAppear {
                    twitterIsLoading = false
                }
            }
        }
        .padding()
    }
}

#Preview {
    TwitterLoginView()
}
