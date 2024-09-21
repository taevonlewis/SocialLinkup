//
//  LinkedIn.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import SwiftUI

struct LinkedInLoginView: View {
    @StateObject private var linkedinViewModel = LinkedInViewModel()
    @State private var linkedinIsLoading = false

    var body: some View {
        VStack(spacing: 15) {
            LoadingView(isLoading: linkedinIsLoading, loadingText: "Logging into LinkedIn...")

            if linkedinViewModel.accessToken.isEmpty && !linkedinIsLoading {
                Button(action: {
                    linkedinIsLoading = true
                    linkedinViewModel.startLinkedInAuthorizationFlow()
                }) {
                    Image("Sign-In-Small---Default")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 50)
                }
            } else if !linkedinViewModel.accessToken.isEmpty {
                Text("LinkedIn: \(linkedinViewModel.name)")
                    .font(.headline)

                Button("Fetch Email") {
                    linkedinViewModel.fetchLinkedInEmailAddress()
                }

                Button("Post to LinkedIn") {
                    linkedinViewModel.postLinkedInPost(message: "Hello LinkedIn from my iOS App!")
                }
                .onAppear {
                    linkedinIsLoading = false
                }
            }
        }
        .padding()
    }
}

#Preview {
    LinkedInLoginView()
}
