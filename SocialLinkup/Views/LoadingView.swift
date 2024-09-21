//
//  LoadingView.swift
//  SocialLinkup
//
//  Copyright © 2024 TaeVon Lewis. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    var isLoading: Bool
    var loadingText: String = "Loading..."
    
    var body: some View {
        if isLoading {
            VStack {
                ProgressView(loadingText)
                    .progressViewStyle(CircularProgressViewStyle())
            }
            .padding()
        }
    }
}

#Preview {
    LoadingView(isLoading: true)
}
