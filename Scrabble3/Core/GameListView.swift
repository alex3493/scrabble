//
//  GameListView.swift
//  Scrabble3
//
//  Created by Alex on 14/10/23.
//

import SwiftUI

struct GameListView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Game list goes here...")
            }
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "gear")
                            .font(.headline)
                    }
                }
            }
        }
    }
}

#Preview {
    GameListView()
}
