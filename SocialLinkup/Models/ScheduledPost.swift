//
//  ScheduledPost.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import Foundation
import SwiftData

@Model
class ScheduledPost {
    @Attribute(.unique) var id: UUID = UUID()
    var content: String
    var mediaData: Data?
    var scheduledDate: Date
    var platforms: [String]
    var isPosted: Bool = false
    
    init(content: String, mediaData: Data? = nil, scheduledDate: Date, platforms: [String]) {
        self.content = content
        self.mediaData = mediaData
        self.scheduledDate = scheduledDate
        self.platforms = platforms
    }
}
