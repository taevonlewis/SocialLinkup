//
//  LinkedInAuth.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import SwiftUI
import WebKit
import Combine

class LinkedInViewModel: ObservableObject, OAuthViewModelProtocol {
    @Published var accessToken: String = ""
    @Published var state: String = ""
    @Published var userURN: String?
    @Published var isLoggedIn = false
    
    let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"] ?? "defaultClientId"
    let clientSecret = ProcessInfo.processInfo.environment["CLIENT_SECRET"]  ?? "defaultClientSecret"
    let redirectUri = ProcessInfo.processInfo.environment["REDIRECT_URL"]  ?? "defaultRedirectUri"
    let authorizationEndpoint = "https://www.linkedin.com/oauth/v2/authorization"
    let tokenEndpoint = "https://www.linkedin.com/oauth/v2/accessToken"
    let userinfo_endpoint = "https://api.linkedin.com/v2/userinfo"
    var authorizationCode: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
            NotificationCenter.default.publisher(for: Notification.Name("LinkedInAuthorization"))
                .sink { notification in
                    if let userInfo = notification.userInfo,
                       let code = userInfo["code"] as? String,
                       let state = userInfo["state"] as? String {
                        if state == self.state {
                            self.exchangeAuthorizationCodeForAccessToken(code: code)
                        } else {
                            print("State does not match. Possible CSRF attack.")
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
        func startAuthorizationFlow() -> URLRequest {
            let randomState = UUID().uuidString
            self.state = randomState
            
            var components = URLComponents(string: authorizationEndpoint)!
            components.queryItems = [
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "client_id", value: clientId),
                URLQueryItem(name: "redirect_uri", value: redirectUri),
                URLQueryItem(name: "state", value: randomState),
                URLQueryItem(name: "scope", value: "openid profile w_member_social email")
            ]
            
            return URLRequest(url: components.url!)
        }
        
    func exchangeAuthorizationCodeForAccessToken(code: String) {
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"

        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(redirectUri)&client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error exchanging authorization code: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

//            print("Response from token exchange: \(String(data: data, encoding: .utf8) ?? "N/A")")

            if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                DispatchQueue.main.async {
//                    print("Access Token: \(tokenResponse.access_token)")
                    self.accessToken = tokenResponse.access_token
                    self.isLoggedIn = true
                    self.fetchLinkedInProfile()
                }
            } else {
                print("Error decoding token response")
            }
        }

        task.resume()
    }
    
    func handleCallbackURL(_ url: URL) {
            let code = getAuthorizationCode(from: url)
            let state = getState(from: url)
            
            if let code = code, let state = state, state == self.state {
                exchangeAuthorizationCodeForAccessToken(code: code)
                isLoggedIn = true
            } else {
                print("State mismatch or invalid code.")
            }
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
    func fetchLinkedInProfile() {
        guard !accessToken.isEmpty else { return }

        var request = URLRequest(url: URL(string: userinfo_endpoint)!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("2.0.0", forHTTPHeaderField: "X-Restli-Protocol-Version")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching profile: \(error.localizedDescription)")
                return
            }

//            if let httpResponse = response as? HTTPURLResponse {
//                print("HTTP Response Status Code: \(httpResponse.statusCode)")
//                if let responseBody = data {
//                    print("Response body: \(String(data: responseBody, encoding: .utf8) ?? "N/A")")
//                }
//            }

            guard let data = data else { return }

            do {
                let profile = try JSONDecoder().decode(LinkedInProfile.self, from: data)
                DispatchQueue.main.async {
//                    print("Fetched LinkedIn URN: \(profile.sub)")
                    self?.userURN = profile.sub                }
            } catch {
                print("Error decoding profile: \(error.localizedDescription)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed profile response: \(responseString)")
                }
            }
        }

        task.resume()
    }
    
    func fetchEmailAddress() {
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
    
    func postContentToLinkedIn(message: String) {
        guard !accessToken.isEmpty else { return }
        
        let url = URL(string: "https://api.linkedin.com/v2/ugcPosts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2.0.0", forHTTPHeaderField: "X-Restli-Protocol-Version")
        
        let postData: [String: Any] = [
            "author": "urn:li:person:\(userURN ?? "")",
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
}

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
}

struct LinkedInProfile: Codable {
    let sub: String
    let name: String
    let given_name: String
    let family_name: String
    let email: String
    let email_verified: Bool
    let picture: String
    let locale: LinkedInLocale

    struct LinkedInLocale: Codable {
        let country: String
        let language: String
    }
}

struct LinkedInEmailResponse: Codable {
    let elements: [EmailElement]
    
    struct EmailElement: Codable {
        let handle: Handle
        
        struct Handle: Codable {
            let emailAddress: String
        }
    }
}

struct EmailElement: Codable {
    let handle: EmailHandle
}

struct EmailHandle: Codable {
    let emailAddress: String
}
