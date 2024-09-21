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
    @Attribute(.unique) private(set) var id: UUID = UUID()
    private(set) var content: String
    private(set) var mediaData: Data?
    private(set) var scheduledDate: Date
    private(set) var platforms: [String]
    private(set) var isPosted: Bool = false
    
    init(content: String, mediaData: Data? = nil, scheduledDate: Date, platforms: [String]) {
        self.content = content
        self.mediaData = mediaData
        self.scheduledDate = scheduledDate
        self.platforms = platforms
    }
}
