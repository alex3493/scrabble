//
//  GameListView.swift
//  Scrabble3
//
//  Created by Alex on 14/10/23.
//

import SwiftUI
import Firebase
import Combine

struct GameListView: View {
    
    @StateObject private var viewModel = GameListViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @AppStorage("PreferredLang") var preferredLanguage: GameLanguage = .ru
    
    var body: some View {
        if authViewModel.currentUser != nil {
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
                                    Text("\(Utils.formatTransactionTimestamp(item.createdAt))")
                                    if item.rules == .express {
                                        Text("Express")
                                    } else if item.rules == .full {
                                        Text("Full")
                                    } else {
                                        Text("Up to 200 points")
                                    }
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
                    .navigationTitle("Games")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading, content: {
                            NavigationLink {
                                GameInfoView()
                                    .navigationBarBackButtonHidden()
                                    .toolbar(.hidden, for: .tabBar)
                            } label: {
                                HStack {
                                    Text("New game")
                                    Spacer()
                                    Image(systemName: "plus")
                                        .font(.headline)
                                }
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
                    Label("Active games", systemImage: "play.fill")
                }
                
                NavigationStack {
                    ArchivedGameListView(contacts: contacts)
                        .navigationTitle("Finished games")
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
                    Label("Finished games", systemImage: "archivebox")
                }
                
                NavigationStack {
                    UserContactsView(viewModel: viewModel.userContactsViewModel)
                        .navigationTitle("My contacts")
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
                    Label("My contacts", systemImage: "person.2.fill")
                }
            }
            .task {
                viewModel.addListenerForContacts(lang: preferredLanguage)
            }
            .onAppear() {
                viewModel.currentUser = authViewModel.currentUser
                print("GameListView APPEARED")
                // TODO: if we remove games listener when we leave list view, we have to reactivate it when we return.
                // Find out how we can do it... Root view only appears once.
            }
            .onDisappear() {
                // TODO: not sure we ever need it - we are using cancellables.
                viewModel.removeListenerForGames()
                viewModel.removeListenerForContacts()
                print("GameListView DISAPPEARED")
            }
            .onReceive(Just(preferredLanguage)) { value in
                print("Language preference changed!", value)
                // We have to reinit games listener when preferred language changes.
                viewModel.addListenerForGames(lang: value)
            }
        }
    }
    
    func gameStatusLabel(game: GameModel) -> String {
        if game.gameStatus == .waiting {
            if isMeGameCreator(game: game) {
                if game.players.count <= 1 {
                    return "Waiting for players"
                } else {
                    return "Ready to start"
                }
            }
            if isMeGamePlayer(game: game) {
                return "Ready to start"
            } else {
                return "Available for joining"
            }
        } else if game.gameStatus == .running {
            return "Game in progress"
        } else if game.gameStatus == .suspended {
            return "Suspended"
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
    
    var contacts: [UserContact] {
        return viewModel.userContactsViewModel.contactUsers
    }
    
}

#Preview {
    GameListView()
}
