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
        TabView {
            NavigationStack {
                List {
                    ForEach(viewModel.games, id: \.id.self) { item in
                        NavigationLink {
                            GameInfoView(gameId: item.id)
                                .navigationBarBackButtonHidden()
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            Text(item.creatorUser.name ?? "")
                            Text ("\(Utils.formatTransactionTimestamp(item.createdAt))")
                        }
                    }
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
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            Image(systemName: "gear")
                                .font(.headline)
                        }
                    }
                }
            }
            .tabItem {
                Label("Активные", systemImage: "play.fill")
            }
            
            NavigationStack {
                List {
                    ForEach(viewModel.archivedGames, id: \.id.self) { item in
                        NavigationLink {
                            GameInfoView(gameId: item.id)
                                .navigationBarBackButtonHidden()
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            Text(item.creatorUser.name ?? "")
                            Text ("\(Utils.formatTransactionTimestamp(item.createdAt))")
                        }
                    }
                }
                .navigationTitle("Архив")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            ProfileView()
                                .toolbar(.hidden, for: .tabBar)
                        } label: {
                            Image(systemName: "gear")
                                .font(.headline)
                        }
                    }
                }
            }
            .tabItem {
                Label("Оконченные", systemImage: "archivebox")
            }
        }
        .task {
            viewModel.addListenerForGames()
            viewModel.addListenerForArchivedGames()
        }
        .onDisappear() {
            // TODO: not sure we ever need it - we are using cancellables.
            viewModel.removeListenerForGames()
            viewModel.removeListenerForArchivedGames()
            print("Games root view disappeared - remove game list listeners")
        }
    }
    
}

#Preview {
    GameListView()
}
