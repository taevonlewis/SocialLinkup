//
//  LinkedInAuth.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import Foundation
import AuthenticationServices
import Combine

class LinkedInViewModel: NSObject, OAuthViewModelProtocol {
    @Published private(set) var accessToken: String = ""
    @Published private(set) var state: String = ""
    @Published private(set) var userURN: String?
    @Published private(set) var name: String = ""
    @Published var isLoggedIn = false
    
    private var clientId = ""
    private var clientSecret = ""
    private var redirectUrl = ""
    private var callbackUrlScheme = ""
    
    private var tokenKey = "LinkedInAccessKey"
    private var nameKey = "LinkedinName"
    
    private let authorizationEndpoint = "https://www.linkedin.com/oauth/v2/authorization"
    private let tokenEndpoint = "https://www.linkedin.com/oauth/v2/accessToken"
    private let userinfo_endpoint = "https://api.linkedin.com/v2/userinfo"
    private var authorizationSession: ASWebAuthenticationSession?

    func startLinkedInAuthorizationFlow() {
        OAuthManager().fetchCredentials(for: "LinkedIn") { [weak self] clientId, clientSecret, redirectUrl, callbackUrlScheme in
                self?.clientId = clientId
                self?.clientSecret = clientSecret
                self?.redirectUrl = redirectUrl
                self?.callbackUrlScheme = callbackUrlScheme
                let randomState = UUID().uuidString
                self?.state = randomState
                
                var components = URLComponents(string: self!.authorizationEndpoint)!
                components.queryItems = [
                    URLQueryItem(name: "response_type", value: "code"),
                    URLQueryItem(name: "client_id", value: clientId),
                    URLQueryItem(name: "redirect_uri", value: redirectUrl),
                    URLQueryItem(name: "state", value: randomState),
                    URLQueryItem(name: "scope", value: "profile openid email w_member_social")
                ]
                
                let authURL = components.url!
                
                self?.authorizationSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackUrlScheme) { callbackURL, error in
                    guard error == nil, let callbackURL = callbackURL else {
                        print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    self?.handleCallbackURL(callbackURL)
                }
                
                self?.authorizationSession?.presentationContextProvider = self
                self?.authorizationSession?.start()
            }
        }

    func handleCallbackURL(_ url: URL) {
        guard let code = getLinkedInAuthorizationCode(from: url) else { return }
        exchangeLinkedInAuthorizationCodeForAccessToken(code: code)
    }

    private func getLinkedInAuthorizationCode(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: true)?
            .queryItems?
            .first { $0.name == "code" }?
            .value
    }

    func exchangeLinkedInAuthorizationCodeForAccessToken(code: String) {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectUrl)&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error exchanging authorization code: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            if let tokenResponse = try? JSONDecoder().decode(LinkedInTokenResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.accessToken = tokenResponse.access_token
                    self.isLoggedIn = true
                    self.saveLoginState(token: self.accessToken, urn: self.userURN)
                    self.fetchLinkedInProfile()
                }
            } else {
                print("Error decoding token response")
            }
        }.resume()
    }

    func saveLoginState(token: String, urn: String?) {
        KeychainHelper.save(key: tokenKey, value: token)
        if let urn = userURN {
            KeychainHelper.save(key: "LinkedInUserURN", value: urn)
        }
    }
    
    func loadLoginState() {
        if let token = KeychainHelper.load(key: tokenKey), !token.isEmpty {
            self.accessToken = token
            self.isLoggedIn = true
            self.name = KeychainHelper.load(key: nameKey) ?? ""
            self.userURN = KeychainHelper.load(key: "LinkedinUserURN")
        }
    }
    
    func fetchLinkedInProfile() {
        guard let token = KeychainHelper.load(key: tokenKey), !token.isEmpty else {
            return
        }

        var request = URLRequest(url: URL(string: userinfo_endpoint)!)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }

            do {
                let profile = try JSONDecoder().decode(LinkedInProfile.self, from: data)
                DispatchQueue.main.async {
                    self.userURN = profile.sub
                    self.name = profile.name
                    self.saveLoginState(token: self.accessToken, urn: self.userURN)
                    KeychainHelper.save(key: self.nameKey, value: self.name)
                }
            } catch {
                print("Error decoding profile: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchLinkedInEmailAddress() {
        guard !accessToken.isEmpty else { return }

        var request = URLRequest(url: URL(string: userinfo_endpoint)!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("2.0.0", forHTTPHeaderField: "X-Restli-Protocol-Version")

        let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard let data = data, error == nil else {
                print("Error fetching user info: \(String(describing: error))")
                return
            }

            if let profileResponse = try? JSONDecoder().decode(LinkedInProfile.self, from: data) {
                DispatchQueue.main.async {
                    let email = profileResponse.email
                    print("Fetched Email: \(email)")
                }
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode profile response: \(responseString)")
                }
            }
        }

        task.resume()
    }
    
    func postLinkedInPost(message: String) {
        guard let token = KeychainHelper.load(key: tokenKey), !token.isEmpty else {
            print("LinkedIn access token is missing.")
            return
        }
        
        guard let userURN = KeychainHelper.load(key: "LinkedInUserURN"), !userURN.isEmpty else {
            print("LinkedIn userURN is missing.")
            return
        }
        
        let url = URL(string: "https://api.linkedin.com/v2/ugcPosts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2.0.0", forHTTPHeaderField: "X-Restli-Protocol-Version")
        
        let postData: [String: Any] = [
            "author": "urn:li:person:\(userURN)",
            "lifecycleState": "PUBLISHED",
            "specificContent": [
                "com.linkedin.ugc.ShareContent": [
                    "shareCommentary": [
                        "text": message
                    ],
                    "shareMediaCategory": "NONE"
                ]
            ],
            "visibility": [
                "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: postData, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }
        
        task.resume()
    }
    
    func logoutOfLinkedIn() {
        accessToken = ""
        userURN = ""
        name = ""
        isLoggedIn = false
        KeychainHelper.delete(key: tokenKey)
        KeychainHelper.delete(key: nameKey)
        print("Logged out of LinkedIn account.")
    }
}

extension LinkedInViewModel: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
        return ASPresentationAnchor()
    }
}
