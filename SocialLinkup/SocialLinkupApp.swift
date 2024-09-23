//
//  SocialLinkupApp.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import SwiftUI
import SwiftData
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      
      Auth.auth().signInAnonymously { (authResult, error) in
          if let error = error {
              print("Firebase anonymous sign-in failed: \(error.localizedDescription)")
          } else {
              print("User signed in anonymously: \(authResult?.user.uid ?? "")")
          }
      }
      
      return true
  }
}

@main
struct SocialLinkupApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let modelContainer: ModelContainer
    private let socialLinkupViewModel: SocialLinkupViewModel

    init() {
        do {
            modelContainer = try ModelContainer(for: UserAccount.self)
            socialLinkupViewModel = SocialLinkupViewModel(modelContext: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(socialLinkupViewModel: socialLinkupViewModel)
                .environment(\.modelContext, modelContainer.mainContext)
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
