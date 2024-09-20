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
    @Attribute(.unique) var id = UUID()
    var platform: String
    var accessToken: String
    var tokenSecret: String?
    var expirationData: Date
    var username: String
    
    init(platform: String, accessToken: String, tokenSecret: String? = nil, expirationData: Date, username: String) {
        self.platform = platform
        self.accessToken = accessToken
        self.tokenSecret = tokenSecret
        self.expirationData = expirationData
        self.username = username
    }
}
