//
//  SocialLinkupViewModel.swift
//  SocialLinkup
//
//  Created by TaeVon Lewis on 9/21/24.
//

import Foundation
import AuthenticationServices
import Combine

class SocialLinkupViewModel: ObservableObject {
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
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        linkedinViewModel.$accessToken.assign(to: &$linkedinAccessToken)
        linkedinViewModel.$name.assign(to: &$linkedinName)
        linkedinViewModel.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                self?.linkedinIsLoggedIn = isLoggedIn
                self?.isLoading = false
            }
            .store(in: &cancellables)
        
        twitterViewModel.$accessToken.assign(to: &$twitterAccessToken)
        twitterViewModel.$username.assign(to: &$twitterUsername)
        twitterViewModel.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                self?.twitterIsLoggedIn = isLoggedIn
                self?.isLoading = false
            }
            .store(in: &cancellables)
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
