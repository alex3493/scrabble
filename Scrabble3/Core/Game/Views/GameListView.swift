//
//  GameListView.swift
//  Scrabble3
//
//  Created by Alex on 14/10/23.
//

import SwiftUI

struct GameListView: View {
    
    @StateObject private var viewModel = GameListViewModel()
    
    var body: some View {
        NavigationStack {
            
            List {
                ForEach(viewModel.games, id: \.id.self) { item in
                    NavigationLink(destination: GameStartView(gameId: item.id)) {
                        Text(item.creatorUser.name ?? "")
                    }
                }
            }
            .task {
                viewModel.addListenerForGames()
            }
            
            .navigationTitle("Games")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    NavigationLink {
                        GameStartView()
                            .navigationBarBackButtonHidden()
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                })
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
