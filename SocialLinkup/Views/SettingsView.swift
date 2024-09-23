//
//  Settings.swift
//  SocialLinkup
//
//  Created by TaeVon Lewis on 9/21/24.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var socialLinkupViewModel: SocialLinkupViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if socialLinkupViewModel.linkedinIsLoggedIn || socialLinkupViewModel.twitterIsLoggedIn {
                    List {
                        Section(header: Text("Accounts")) {
                            if socialLinkupViewModel.linkedinIsLoggedIn {
                                Button("Log out of LinkedIn") {
                                    socialLinkupViewModel.linkedinLogout()
                                }
                            }
                            
                            if socialLinkupViewModel.twitterIsLoggedIn {
                                Button("Log out of Twitter") {
                                    socialLinkupViewModel.twitterLogout()
                                }
                            }
                        }
                    }
                } else {
                    Text("You are not signed into any accounts.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

//#Preview {
//    SettingsView(socialLinkupViewModel: SocialLinkupViewModel())
//}
