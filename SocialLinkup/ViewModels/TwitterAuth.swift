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
    @Published var accessToken: String = ""
    @Published var isLoggedIn = false

    private let consumerKey = ProcessInfo.processInfo.environment["TWITTER_CLIENT_ID"] ?? "defaultConsumerKey"
    private let consumerSecret = ProcessInfo.processInfo.environment["TWITTER_CLIENT_SECRET"] ?? "defaultConsumerSecret"

    private var presentationAnchor: ASPresentationAnchor?
    private var currentSession: ASWebAuthenticationSession?
    private var codeVerifier: String = ""
    private var state: String = ""
    private var refreshToken: String = ""

    func generateCodeVerifier() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        var codeVerifier = ""
        for _ in 0..<128 {
            codeVerifier.append(characters.randomElement()!)
        }
        return codeVerifier
    }

    func generateCodeChallenge(codeVerifier: String) -> String {
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

    func constructAuthorizationURL() -> URL? {
        let clientID = consumerKey
        let redirectURI = ProcessInfo.processInfo.environment["REDIRECT_URL"]
        let scopes = "tweet.write tweet.read users.read offline.access"
        let state = UUID().uuidString
        self.state = state

        codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier)
        let codeChallengeMethod = "S256"

        var components = URLComponents()
        components.scheme = "https"
        components.host = "twitter.com"
        components.path = "/i/oauth2/authorize"

        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod)
        ]

//        print("Constructed Authorization URL: \(components.url?.absoluteString ?? "Invalid URL")")
        return components.url
    }

    func startAuthentication(presentationAnchor: ASPresentationAnchor) {
        self.presentationAnchor = presentationAnchor

        guard let authURL = constructAuthorizationURL() else {
            print("Failed to construct authorization URL")
            return
        }

        let callbackURLScheme = "sociallinkup"

        print("Starting Web Authentication Session with URL: \(authURL.absoluteString)")
        currentSession = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
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

        currentSession?.presentationContextProvider = self
        currentSession?.prefersEphemeralWebBrowserSession = true
        currentSession?.start()
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

        // Verify state
        guard let returnedState = returnedState, returnedState == self.state else {
            print("State mismatch: expected \(self.state), got \(returnedState ?? "nil")")
            return
        }

//        print("Authorization code received: \(code)")
        exchangeCodeForToken(code: code)
    }

    func exchangeCodeForToken(code: String) {
        let tokenURL = "https://api.x.com/2/oauth2/token"
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let clientID = consumerKey
        let redirectURI = ProcessInfo.processInfo.environment["REDIRECT_URL"]

        let bodyParams = [
            "code": code,
            "grant_type": "authorization_code",
            "client_id": clientID,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]

        let bodyString = bodyParams
            .map { "\($0.key)=\($0.value!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

//        print("Exchanging authorization code for token with body: \(bodyString)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error exchanging code for token: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data in response")
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
                }
            } else {
                print("Failed to decode token response")
            }
        }

        task.resume()
    }

    func postTweet(tweetText: String) {
        guard !accessToken.isEmpty else {
            print("Access Token is missing.")
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

                if let tweetResponse = try? JSONDecoder().decode(TweetResponse.self, from: data) {
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
}

struct TwitterTokenResponse: Codable {
    let token_type: String
    let expires_in: Int
    let access_token: String
    let scope: String
    let refresh_token: String?
}

struct TweetResponse: Codable {
    let data: TweetData

    struct TweetData: Codable {
        let id: String
        let text: String
    }
}
