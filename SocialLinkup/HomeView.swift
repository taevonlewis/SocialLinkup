//
//  ContentView.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    let socialLinkupViewModel: SocialLinkupViewModel
    
    var body: some View {
        TabView {
            Tab("Post Message", systemImage: "text.below.photo.fill") {
                SocialLinkupView(socialLinkupViewModel: socialLinkupViewModel)
            }
            
            Tab("Settings", systemImage: "gearshape") {
                SettingsView(socialLinkupViewModel: socialLinkupViewModel)
            }
        }
    }
}

//#Preview {
//    HomeView()
//        .modelContainer(for: [UserAccount.self])
//}
