//
//  TwitterAuth.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit

class TwitterViewModel: NSObject, ObservableObject, OAuthViewModelProtocol, ASWebAuthenticationPresentationContextProviding {
    @Published private(set) var accessToken: String = ""
    @Published private(set) var isLoggedIn = false
    @Published private(set) var username: String = ""
    
    private var consumerKey = ""
    private var consumerSecret = ""
    private var redirectUrl = ""
    private var callbackUrlScheme = ""

    private var tokenKey = "TwitterAccessToken"
    private var usernameKey = "TwitterUsername"
    
    private var presentationAnchor: ASPresentationAnchor?
    private var currentSession: ASWebAuthenticationSession?
    private var codeVerifier: String = ""
    private var state: String = ""
    private var refreshToken: String = ""

    private func generateTwitterCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        var codeVerifier = ""
        for _ in 0..<128 {
            codeVerifier.append(characters.randomElement()!)
        }
        return codeVerifier
    }

    private func generateTwitterCodeChallenge(codeVerifier: String) -> String {
        let data = Data(codeVerifier.utf8)
        let hashed = SHA256.hash(data: data)
        let hashData = Data(hashed)
        let base64String = hashData.base64EncodedString()
        let base64url = base64String
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64url
    }

    func constructTwitterAuthorizationURL() -> URL? {
        let clientID = consumerKey
        let redirectUrl = redirectUrl
        let scopes = "tweet.write tweet.read users.read offline.access"
        let state = UUID().uuidString
        self.state = state

        codeVerifier = generateTwitterCodeVerifier()
        let codeChallenge = generateTwitterCodeChallenge(codeVerifier: codeVerifier)
        let codeChallengeMethod = "S256"

        var components = URLComponents()
        components.scheme = "https"
        components.host = "twitter.com"
        components.path = "/i/oauth2/authorize"

        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectUrl),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod)
        ]

//        print("Constructed Authorization URL: \(components.url?.absoluteString ?? "Invalid URL")")
        return components.url
    }

    func startTwitterAuthentication(presentationAnchor: ASPresentationAnchor) {
        OAuthManager().fetchCredentials(for: "Twitter") { [weak self] consumerKey, consumerSecret, redirectUrl, callbackUrlScheme in
            guard let self = self else {
                return
            }
            
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.redirectUrl = redirectUrl
            self.callbackUrlScheme = callbackUrlScheme
            
            guard !consumerKey.isEmpty, !consumerSecret.isEmpty, !redirectUrl.isEmpty, !callbackUrlScheme.isEmpty else {
                print("Invalid Twitter credentials")
                return
            }
            
            self.presentationAnchor = presentationAnchor
            
            guard let authURL = self.constructTwitterAuthorizationURL() else {
                print("Failed to construct authorization URL")
                return
            }
            
            let callbackURLScheme = callbackUrlScheme
            
            print("Starting Web Authentication Session with URL: \(authURL.absoluteString)")
            self.currentSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
                if let error = error {
                    print("Authentication error: \(error.localizedDescription)")
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    print("No callback URL")
                    return
                }
                
                print("Authentication Callback URL: \(callbackURL.absoluteString)")
                self.handleCallbackURL(callbackURL)
            }
            
            self.currentSession?.presentationContextProvider = self
            self.currentSession?.prefersEphemeralWebBrowserSession = true
            self.currentSession?.start()
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentationAnchor!
    }

    func handleCallbackURL(_ url: URL) {
        print("Handling Callback URL: \(url.absoluteString)")

        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let returnedState = components?.queryItems?.first(where: { $0.name == "state" })?.value
        let code = components?.queryItems?.first(where: { $0.name == "code" })?.value

        guard let code = code else {
            print("No code returned in callback URL")
            return
        }

        guard let returnedState = returnedState, returnedState == self.state else {
            print("State mismatch: expected \(self.state), got \(returnedState ?? "nil")")
            return
        }

//        print("Authorization code received: \(code)")
        exchangeTwitterCodeForToken(code: code)
    }

    private func exchangeTwitterCodeForToken(code: String) {
        let tokenURL = "https://api.x.com/2/oauth2/token"
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let clientID = consumerKey
        let redirectURI = redirectUrl

        let bodyParams = [
            "code": code,
            "grant_type": "authorization_code",
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]

        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

//        print("Exchanging authorization code for token with body: \(bodyString)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error exchanging code for token: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

//            if let httpResponse = response as? HTTPURLResponse {
//                print("Token Exchange Response Status Code: \(httpResponse.statusCode)")
//                print("Token Exchange Headers: \(httpResponse.allHeaderFields)")
//            }
//
//            if let responseString = String(data: data, encoding: .utf8) {
//                print("Token response: \(responseString)")
//            }

            if let tokenResponse = try? JSONDecoder().decode(TwitterTokenResponse.self, from: data) {
                DispatchQueue.main.async {
                    self.accessToken = tokenResponse.access_token
                    self.refreshToken = tokenResponse.refresh_token ?? ""
                    self.isLoggedIn = true
                    self.saveLoginState(token: self.accessToken)
                    self.fetchTwitterProfile()
                }
            } else {
                print("Failed to decode token response")
            }
        }

        task.resume()
    }

    func saveLoginState(token: String) {
        KeychainHelper.save(key: tokenKey, value: token)
    }
    
    func loadLoginState() {
        if let token = KeychainHelper.load(key: tokenKey), !token.isEmpty {
            self.accessToken = token
            self.isLoggedIn = true
            self.username = KeychainHelper.load(key: usernameKey) ?? ""
        }
    }
    
    func fetchTwitterProfile() {
        guard let token = KeychainHelper.load(key: tokenKey), !token.isEmpty else {
            print("Access Token is missing.")
            return
        }

        let profileURL = "https://api.x.com/2/users/me?user.fields=created_at,description,profile_image_url,public_metrics,username,url"
        var request = URLRequest(url: URL(string: profileURL)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching profile: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data in response")
                return
            }

            if let userResponse = try? JSONDecoder().decode(TwitterUserResponse.self, from: data) {
                DispatchQueue.main.async {
                    print("User ID: \(userResponse.data.id)")
                    print("Name: \(userResponse.data.name)")
                    
                    self.username = userResponse.data.username
                    print("Username: \(self.username)")
                    KeychainHelper.save(key: self.usernameKey, value: self.username)

                    print("Url: \(userResponse.data.url ?? "placeholderUrl")")
                    
                    if let createdAt = userResponse.data.created_at {
                        print("Account Created At: \(createdAt)")
                    }
                    if let description = userResponse.data.description {
                        print("Description: \(description)")
                    }
                    if let profileImageURL = userResponse.data.profile_image_url {
                        print("Profile Image URL: \(profileImageURL)")
                    }
                    if let publicMetrics = userResponse.data.public_metrics {
                        print("Followers Count: \(publicMetrics.followers_count)")
                        print("Following Count: \(publicMetrics.following_count)")
                        print("Tweet Count: \(publicMetrics.tweet_count)")
                        print("Listed Count: \(publicMetrics.listed_count)")
                    }
                }
            } else {
                print("Failed to decode user response")
            }
        }

        task.resume()
    }
    
    func postTwitterTweet(tweetText: String) {
        guard let token = KeychainHelper.load(key: tokenKey), !token.isEmpty else {
            return
        }

        let tweetURL = "https://api.x.com/2/tweets"
        var request = URLRequest(url: URL(string: tweetURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let tweetBody: [String: Any] = [
            "text": tweetText
        ]

        do {
            let jsonBody = try JSONSerialization.data(withJSONObject: tweetBody, options: .fragmentsAllowed)
            request.httpBody = jsonBody

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error posting tweet: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    print("No data in response")
                    return
                }

//                if let httpResponse = response as? HTTPURLResponse {
//                    print("Tweet Post Response Status Code: \(httpResponse.statusCode)")
//                    print("Tweet Post Headers: \(httpResponse.allHeaderFields)")
//                }
//
//                if let responseString = String(data: data, encoding: .utf8) {
//                    print("Tweet response: \(responseString)")
//                }

                if let tweetResponse = try? JSONDecoder().decode(TwitterTweetResponse.self, from: data) {
                    print("Tweet posted successfully with ID: \(tweetResponse.data.id)")
                } else {
                    print("Failed to decode tweet response")
                }
            }
            task.resume()
        } catch {
            print("Error serializing tweet body: \(error.localizedDescription)")
        }
    }
    
    func logoutOfTwitter() {
        accessToken = ""
        username = ""
        isLoggedIn = false
        KeychainHelper.delete(key: tokenKey)
        KeychainHelper.delete(key: usernameKey)
        print("Logged out of LinkedIn account.")
    }
}
