//
//  GameListView.swift
//  Scrabble3
//
//  Created by Alex on 14/10/23.
//

import SwiftUI
import Firebase

struct GameListView: View {
    
    @StateObject private var viewModel = GameListViewModel()
    
    var body: some View {
        NavigationStack {
            
            List {
                ForEach(viewModel.games, id: \.id.self) { item in
                    NavigationLink {
                        GameInfoView(gameId: item.id)
                            .navigationBarBackButtonHidden()
                    } label: {
                        Text(item.creatorUser.name ?? "")
                        Text ("\(Utils.formatTransactionTimestamp(item.createdAt))")
                    }
                }
            }
            .task {
                viewModel.addListenerForGames()
            }
            
            .navigationTitle("Игры")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    NavigationLink {
                        GameInfoView()
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
