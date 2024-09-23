//
//  SocialLinkupView.swift
//  SocialLinkup
//
//  Created by TaeVon Lewis on 9/21/24.
//

import SwiftUI
import SwiftData

struct EnvironmentDebugView: View {
    var body: some View {
        VStack {
            Text("LinkedIn Client ID: \(ProcessInfo.processInfo.environment["LINKEDIN_CLIENT_ID"] ?? "missing")")
            Text("Twitter Client ID: \(ProcessInfo.processInfo.environment["TWITTER_CLIENT_ID"] ?? "missing")")
        }
        .padding()
    }
}

struct SocialLinkupView: View {
    @StateObject private var socialLinkupViewModel: SocialLinkupViewModel
    @State private var message = ""

    init(socialLinkupViewModel: SocialLinkupViewModel) {
        _socialLinkupViewModel = StateObject(wrappedValue: socialLinkupViewModel)
    }
  
    var body: some View {
        VStack(spacing: 15) {
            if socialLinkupViewModel.isLoading {
                LoadingView(isLoading: socialLinkupViewModel.isLoading, loadingText: socialLinkupViewModel.loadingMessage)
            } else {
                if !socialLinkupViewModel.linkedinIsLoggedIn {
                    Button(action: {
                        socialLinkupViewModel.loginToLinkedin()
                    }) {
                        Image("Sign-In-Small---Default")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 50)
                    }
                } else {
                    Text("Logged in as: \(socialLinkupViewModel.linkedinName)")
                }

                if !socialLinkupViewModel.twitterIsLoggedIn {
                    Button(action: {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            socialLinkupViewModel.loginToTwitter(presentationAnchor: window)
                        }
                    }) {
                        Image("Twitter-Gray-Sign-In")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 50)
                    }
                } else {
                    Text("Logged in as: @\(socialLinkupViewModel.twitterUsername)")
                }

                if socialLinkupViewModel.linkedinIsLoggedIn || socialLinkupViewModel.twitterIsLoggedIn {
                    TextField("Enter your message", text: $message)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)

                    Button("Post Message") {
                        socialLinkupViewModel.postMessage(message: message)
                    }
                    .padding(.top)
                }
            }
        }
        .padding()
    }
}

//#Preview {
//    SocialLinkupView()
//}
