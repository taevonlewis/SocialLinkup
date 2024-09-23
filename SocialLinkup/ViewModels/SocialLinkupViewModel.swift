//
//  SocialLinkupViewModel.swift
//  SocialLinkup
//
//  Created by TaeVon Lewis on 9/21/24.
//

import Foundation
import AuthenticationServices
import Combine
import SwiftData
import SwiftUICore

class SocialLinkupViewModel: ObservableObject, DynamicProperty {
    private var modelContext: ModelContext
    
    @Published private(set) var linkedinAccessToken: String = ""
    @Published private(set) var linkedinIsLoggedIn: Bool = false
    @Published private(set) var linkedinName: String = ""
    
    @Published private(set) var twitterAccessToken: String = ""
    @Published private(set) var twitterIsLoggedIn: Bool = false
    @Published private(set) var twitterUsername: String = ""
    
    private let linkedinViewModel = LinkedInViewModel()
    private let twitterViewModel = TwitterViewModel()
    
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = "Loading..."
    
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        linkedinViewModel.loadLoginState()
        twitterViewModel.loadLoginState()
        setupBindings()
        loadLoginState()
    }
    
    private func setupBindings() {
        linkedinViewModel.$accessToken.assign(to: &$linkedinAccessToken)
        linkedinViewModel.$name.assign(to: &$linkedinName)
        linkedinViewModel.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                self?.linkedinIsLoggedIn = isLoggedIn
                self?.isLoading = !isLoggedIn
                
                if isLoggedIn {
                    self?.saveLoginState(platform: "LinkedIn", accessToken: self?.linkedinAccessToken ?? "", username: self?.linkedinName ?? "")
                } else {
                    self?.isLoading = !isLoggedIn
                }
            }
            .store(in: &cancellables)
        
        twitterViewModel.$accessToken.assign(to: &$twitterAccessToken)
        twitterViewModel.$username.assign(to: &$twitterUsername)
        twitterViewModel.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                self?.twitterIsLoggedIn = isLoggedIn
                self?.isLoading = false
                
                if isLoggedIn {
                    self?.saveLoginState(platform: "Twitter", accessToken: self?.twitterAccessToken ?? "", username: self?.twitterUsername ?? "")
                }
                
            }
            .store(in: &cancellables)
    }
    
    func saveLoginState(platform: String, accessToken: String, username: String? = nil) {
        let userAccount = UserAccount(platform: platform, accessToken: accessToken, username: username)
        modelContext.insert(userAccount)
        
        do {
            try modelContext.save()
            print("Login state saved for \(platform)")
        } catch {
            print("Error saving login state for \(platform): \(error)")
        }
    }
    
    func loadLoginState() {
        linkedinViewModel.loadLoginState()
        twitterViewModel.loadLoginState()
        
        self.linkedinAccessToken = linkedinViewModel.accessToken
        self.linkedinName = linkedinViewModel.name
        
        self.twitterAccessToken = twitterViewModel.accessToken
        self.twitterUsername = twitterViewModel.username
    }
    
    private func removeLoginState(platform: String) {
        let fetchDescriptor = FetchDescriptor<UserAccount>()
        
        if let accounts = try? modelContext.fetch(fetchDescriptor) {
            accounts.filter { $0.platform == platform }.forEach { account in
                modelContext.delete(account)
            }
            
            do {
                try modelContext.save()
                print("Login state removed for \(platform)")
                if platform == "LinkedIn" {
                    linkedinViewModel.logoutOfLinkedIn()
                    linkedinAccessToken = ""
                    linkedinIsLoggedIn = false
                    linkedinName = ""
                } else if platform == "Twitter" {
                    twitterViewModel.logoutOfTwitter()
                    twitterAccessToken = ""
                    twitterIsLoggedIn = false
                    twitterUsername = ""
                }
            } catch {
                print("Error removing login state for \(platform): \(error)")
            }
        }
    }
        
        func loginToLinkedin() {
            loadingMessage = "Logging into Linkedin..."
            isLoading = true
            linkedinViewModel.startLinkedInAuthorizationFlow()
        }
        
        func loginToTwitter(presentationAnchor: ASPresentationAnchor) {
            loadingMessage = "Logging into Twitter..."
            isLoading = true
            twitterViewModel.startTwitterAuthentication(presentationAnchor: presentationAnchor)
        }
        
        func linkedinLogout() {
            linkedinViewModel.logoutOfLinkedIn()
            removeLoginState(platform: "LinkedIn")
        }
        
        func twitterLogout() {
            twitterViewModel.logoutOfTwitter()
            removeLoginState(platform: "Twitter")
        }
        
        func postMessage(message: String) {
            isLoading = true
            loadingMessage = "Posting message..."
            
            if linkedinIsLoggedIn {
                linkedinViewModel.postLinkedInPost(message: message)
            }
            
            if twitterIsLoggedIn {
                twitterViewModel.postTwitterTweet(tweetText: message)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isLoading = false
            }
        }
}
