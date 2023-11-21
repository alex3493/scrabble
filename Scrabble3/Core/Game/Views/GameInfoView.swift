//
//  GameStartView.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import SwiftUI
import Firebase

struct GameInfoView: View {
    
    @State var gameId: String? = nil
    
    @StateObject private var viewModel = GameInfoViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let errorStore = ErrorStore.shared
    
    var body: some View {
        Group {
            if viewModel.isGameRunning, let game = viewModel.game, viewModel.isMeGamePlayer {
                GamePlayView(game: game)
            } else if viewModel.isGameFinished, let game = viewModel.game {
                GameResultView(game: game)
                    .navigationTitle("Игра окончена")
            } else {
                VStack {
                    if let game = viewModel.game, let gameId = gameId {
                        List {
                            Section("Игра") {
                                Text("\(game.creatorUser.name!): \(Utils.formatTransactionTimestamp(game.createdAt))")
                                // Text("Current game ID: \(game.id)")
                                Text("Current game status: \(game.gameStatus.rawValue)")
                            }
                            
                            Section("Игроки") {
                                ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                                    HStack(spacing: 12) {
                                        // TODO: issue here - when user leaves game we have index-out-of range error!
                                        // Image(systemName: game.turn == index ? "person.fill" : "person")
                                        Text(item.user.name!)
                                        Spacer()
                                        Text("\(item.score)")
                                    }
                                }
                            }
                        }
                        
                        if (viewModel.canDeleteGame) {
                            ActionButton(label: "УДАЛИТЬ ИГРУ", action: {
                                do {
                                    try await viewModel.deleteGame(gameId: gameId)
                                    dismiss()
                                } catch {
                                    print("DEBUG :: Error deleting game: \(error.localizedDescription)")
                                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                                }
                            }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed), maxWidth: true)
                        } else if viewModel.canLeaveGame {
                            ActionButton(label: "ВЫЙТИ", action: {
                                do {
                                    try await viewModel.leaveGame(gameId: gameId)
                                    dismiss()
                                } catch {
                                    print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                                }
                            }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: true)
                        } else if viewModel.canJoinGame {
                            ActionButton(label: "ПРИСОЕДИНИТЬСЯ", action: {
                                do {
                                    try await viewModel.joinGame(gameId: gameId)
                                } catch {
                                    print("DEBUG :: Error joining game: \(error.localizedDescription)")
                                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                                }
                            }, buttonSystemImage: "square.and.arrow.down", backGroundColor: Color(.systemBlue), maxWidth: true)
                        }
                        if (viewModel.canStartGame) {
                            ActionButton(label: "НАЧАТЬ ИГРУ", action: {
                                do {
                                    try await viewModel.startGame(gameId: gameId)
                                } catch {
                                    print("DEBUG :: Error starting game: \(error.localizedDescription)")
                                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                                }
                            }, buttonSystemImage: "play", backGroundColor: Color(.systemBlue), maxWidth: true)
                        }
                        if (viewModel.canResumeGame) {
                            ActionButton(label: "ПРОДОЛЖИТЬ ИГРУ", action: {
                                do {
                                    try await viewModel.resumeGame(gameId: gameId)
                                } catch {
                                    print("DEBUG :: Error resuming game: \(error.localizedDescription)")
                                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                                }
                            }, buttonSystemImage: "play", backGroundColor: Color(.systemBlue), maxWidth: true)
                            
                            ActionButton(label: "ВЫЙТИ ИЗ ИГРЫ", action: {
                                do {
                                    try await viewModel.abortGame(gameId: gameId)
                                } catch {
                                    print("DEBUG :: Error aborting game: \(error.localizedDescription)")
                                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                                }
                            }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed), maxWidth: true)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 3) {
                            Text("Все игры")
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        }
                        .font(.system(size: 14))
                    }
                    .padding()
                    
                }
                .task {
                    print("GameInfoView task")
                    if (gameId == nil) {
                        do {
                            try await createGame()
                            viewModel.addListenerForGame()
                        } catch {
                            print("DEBUG :: Error creating game: \(error.localizedDescription)")
                            errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                        }
                    } else {
                        guard let gameId = gameId else { return }
                        await viewModel.loadGame(gameId: gameId)
                        viewModel.addListenerForGame()
                    }
                }
                .onAppear() {
                    print("GameInfoView onAppear")
                }
                .onDisappear() {
                    // TODO: it works to avoid double-update for game, but it breaks "suspend game" feature.
                    // We put it on hold: this view is displayed conditionally in GameInfoView, so we need
                    // another instance of game subscriber there.
                    print("GameInfoView disappeared")
                    // viewModel.removeListenerForGame()
                }
            }
        }.onAppear() {
            viewModel.currentUser = authViewModel.currentUser
            print("GameInfoView APPEARED")
        }
    }
    
    func createGame() async throws {
        guard let user = authViewModel.currentUser else { return }
        
        gameId = try await viewModel.createGame(byUser: user)
        
        print ("Game created. ID: \(String(describing: gameId)), User: \(String(describing: user.email))")
    }
    
}

#Preview {
    GameInfoView()
}
