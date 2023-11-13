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
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
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
//        .onAppear() {
//            viewModel.currentUser = authViewModel.currentUser
//        }
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
            if isMeGameCreator(game: game) {
                if game.players.count <= 1 {
                    return "Ожидание игроков"
                } else {
                    return "Готова к старту"
                }
            }
            if isMeGamePlayer(game: game) {
                return "Готова к старту"
            } else {
                return "Доступна для подключения"
            }
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
            if isMeGameCreator(game: game) {
                if game.players.count <= 1 {
                    return "person.fill.questionmark"
                } else {
                    return "flag.fill"
                }
            }
            if isMeGamePlayer(game: game) {
                return "flag.fill"
            } else {
                return "person.crop.circle.fill.badge.plus"
            }
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
    
    func isMeGameCreator(game: GameModel) -> Bool {
        guard let user = authViewModel.currentUser else { return false }
        
        return game.creatorUser.userId == user.userId
    }
    
    func isMeGamePlayer(game: GameModel) -> Bool {
        guard let user = authViewModel.currentUser else { return false }
        
        return !isMeGameCreator(game: game) && game.players.first { $0.user.userId == user.userId } != nil
    }
    
}

#Preview {
    GameListView()
}
