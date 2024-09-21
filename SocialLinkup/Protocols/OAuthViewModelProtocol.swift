//
//  OAuthViewModelProtocol.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import Foundation

protocol OAuthViewModelProtocol: ObservableObject {
    func handleCallbackURL(_ url: URL)
}
