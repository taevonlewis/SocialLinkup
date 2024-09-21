//
//  UserAccount.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import Foundation
import SwiftData

@Model
class UserAccount {
    @Attribute(.unique) private(set) var id = UUID()
    private(set) var platform: String
    private(set) var accessToken: String
    private(set) var tokenSecret: String?
    private(set) var expirationData: Date
    private(set) var username: String
    
    init(platform: String, accessToken: String, tokenSecret: String? = nil, expirationData: Date, username: String) {
        self.platform = platform
        self.accessToken = accessToken
        self.tokenSecret = tokenSecret
        self.expirationData = expirationData
        self.username = username
    }
}
