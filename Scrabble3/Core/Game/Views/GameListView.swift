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
                            HStack {
                                Text(item.creatorUser.name ?? "")
                                Text ("\(Utils.formatTransactionTimestamp(item.createdAt))")
                                Spacer()
                                HStack(spacing: 12) {
                                    Text(gameStatusLabel(game: item))
                                    Image(systemName: gameStatusIcon(game: item))
                                        .frame(width: 24)
                                }
                            }
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
                            HStack {
                                Text(item.creatorUser.name ?? "")
                                Text ("\(Utils.formatTransactionTimestamp(item.createdAt))")
                                Spacer()
                                HStack(spacing: 12) {
                                    Text(gameStatusLabel(game: item))
                                    Image(systemName: gameStatusIcon(game: item))
                                        .frame(width: 24)
                                }
                            }
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
    
    // TODO: we have to show different status icon and label for waiting games.
    // - game creator waiting for other users.
    // - game available for joining by another player.
    // - game with two or more players - ready to start.
    
    func gameStatusLabel(game: GameModel) -> String {
        if game.gameStatus == .waiting {
            return "Ожидание игроков"
        } else if game.gameStatus == .running {
            return "Идет игра"
        } else if game.gameStatus == .suspended {
            return "Приостановлена"
        } else if game.gameStatus == .finished {
            return "Окончена"
        } else if game.gameStatus == .aborted {
            return "Отменена"
        }
        return ""
    }
    
    func gameStatusIcon(game: GameModel) -> String {
        if game.gameStatus == .waiting {
            return "person.2.badge.gearshape"
        } else if game.gameStatus == .running {
            return "play.fill"
        } else if game.gameStatus == .suspended {
            return "playpause.fill"
        } else if game.gameStatus == .finished {
            return "flag.2.crossed.fill"
        } else if game.gameStatus == .aborted {
            return "xmark.circle.fill"
        }
        return ""
    }
    
}

#Preview {
    GameListView()
}
