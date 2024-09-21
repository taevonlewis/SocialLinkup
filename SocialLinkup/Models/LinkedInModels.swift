//
//  LinkedInModels.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import Foundation

struct LinkedInTokenResponse: Codable {
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
    let elements: [LinkedInEmailElement]

    struct LinkedInEmailElement: Codable {
        let handle: LinkedInHandle

        struct LinkedInHandle: Codable {
            let emailAddress: String
        }
    }
}
