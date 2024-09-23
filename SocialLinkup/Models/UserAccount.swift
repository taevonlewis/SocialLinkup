//
//  UserAccount.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import Foundation
import SwiftData

@Model
class UserAccount: ObservableObject {
    @Attribute(.unique) var id: UUID = UUID()
    var platform: String
    var accessToken: String
    var username: String?

    init(platform: String, accessToken: String, username: String? = nil) {
        self.platform = platform
        self.accessToken = accessToken
        self.username = username
    }
}
