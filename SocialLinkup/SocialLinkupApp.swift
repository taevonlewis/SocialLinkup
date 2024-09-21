//
//  SocialLinkupApp.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import SwiftUI

@main
struct SocialLinkupApp: App {
    @StateObject private var viewModel = LinkedInViewModel()


    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(viewModel)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
            guard url.scheme == "sociallinkup" else {
                return
            }
            
            if url.host == "auth", url.path == "/linkedin" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                let code = components?.queryItems?.first(where: { $0.name == "code" })?.value
                let state = components?.queryItems?.first(where: { $0.name == "state" })?.value
                
                if let code = code, let state = state {
                    NotificationCenter.default.post(name: Notification.Name("LinkedInAuthorization"), object: nil, userInfo: ["code": code, "state": state])
                }
            }
        }
}
