//
//  Item.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
