//
//  ContentView.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//


import SwiftUI
import SwiftData

struct HomeView: View {
    
    var body: some View {
        NavigationView {
            VStack {
                LinkedInLoginView()
                TwitterView()
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserAccount.self])
}
