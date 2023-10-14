//
//  ContentView.swift
//  Scrabble3
//
//  Created by Alex on 1/9/23.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    // @EnvironmentObject var errorStore: ErrorStore
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                ProfileView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthWithEmailViewModel())
        // .environmentObject(ErrorStore.shared)
}
