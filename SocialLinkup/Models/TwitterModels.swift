//
//  TwitterModels.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import Foundation

struct TwitterTokenResponse: Codable {
    let token_type: String
    let expires_in: Int
    let access_token: String
    let scope: String
    let refresh_token: String?
}

struct TwitterUserResponse: Codable {
    let data: TwitterUserData
    let includes: Includes?
    
    struct TwitterUserData: Codable {
        let id: String
        let name: String
        let username: String
        let created_at: String?
        let description: String?
        let profile_image_url: String?
        let public_metrics: PublicMetrics?
        let url: String?
    }
    
    struct PublicMetrics: Codable {
        let followers_count: Int
        let following_count: Int
        let tweet_count: Int
        let listed_count: Int
    }
    
    struct Includes: Codable {
        let tweets: [TwitterTweetResponse.TwitterTweetData]?
    }
}

struct TwitterTweetResponse: Codable {
    let data: TwitterTweetData

    struct TwitterTweetData: Codable {
        let id: String
        let text: String
    }
}
