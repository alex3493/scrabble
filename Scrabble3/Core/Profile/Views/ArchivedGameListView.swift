//
//  ArchivedGameListView.swift
//  Scrabble3
//
//  Created by Alex on 23/11/23.
//

import SwiftUI

struct ArchivedGameListView: View {
    
    @ObservedObject var viewModel = ArchivedGameListViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    let errorStore = ErrorStore.shared
    
    // Here we have current user contacts.
    let contacts: [UserContact]
    
    var body: some View {
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
                
                if item == viewModel.games.last && !viewModel.allGamesFetched {
                    ProgressView().onAppear() {
                        Task {
                            do {
                                try await viewModel.fetchGames()
                            } catch {
                                print("DEBUG:: Error fetching users", error.localizedDescription)
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
        .task {
            do {
                try await viewModel.fetchGames()
            } catch {
                print("DEBUG :: Error fetching users", error.localizedDescription)
                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
            }
        }
        .onAppear() {
            print("Archived game list view appeared")
            viewModel.currentUser = authViewModel.currentUser
            viewModel.contacts = contacts
        }
    }
    
    func gameStatusLabel(game: GameModel) -> String {
        if game.gameStatus == .finished {
            return "Окончена"
        } else if game.gameStatus == .aborted {
            return "Отменена"
        }
        return ""
    }
    
    func gameStatusIcon(game: GameModel) -> String {
        if game.gameStatus == .finished {
            return "flag.2.crossed.fill"
        } else if game.gameStatus == .aborted {
            return "xmark.circle.fill"
        }
        return ""
    }
}

#Preview {
    ArchivedGameListView(contacts: [])
}
