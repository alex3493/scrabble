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
        if viewModel.isGameRunning, let game = viewModel.game, viewModel.isMeGamePlayer {
            GamePlayView(game: game)
        } else {
            VStack {
                if let game = viewModel.game, let gameId = gameId {
                    List {
                        Section("Game") {
                            Text("\(game.creatorUser.name!): \(Utils.formatTransactionTimestamp(game.createdAt))")
                            // Text("Current game ID: \(game.id)")
                            Text("Current game status: \(game.gameStatus.rawValue)")
                        }
                        
                        Section("Players") {
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
                    
                    if (viewModel.isMeGameCreator) {
                        ActionButton(label: "DELETE GAME", action: {
                            do {
                                try await viewModel.deleteGame(gameId: gameId)
                                dismiss()
                            } catch {
                                print("DEBUG :: Error deleting game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed), maxWidth: true)
                    } else if viewModel.canLeaveGame {
                        ActionButton(label: "LEAVE GAME", action: {
                            do {
                                try await viewModel.leaveGame(gameId: gameId)
                                dismiss()
                            } catch {
                                print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: true)
                    } else if viewModel.canJoinGame {
                        ActionButton(label: "JOIN GAME", action: {
                            do {
                                try await viewModel.joinGame(gameId: gameId)
                            } catch {
                                print("DEBUG :: Error joining game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "square.and.arrow.down", backGroundColor: Color(.systemBlue), maxWidth: true)
                    }
                    if (viewModel.canStartGame) {
                        ActionButton(label: "START GAME", action: {
                            do {
                                try await viewModel.startGame(gameId: gameId)
                            } catch {
                                print("DEBUG :: Error starting game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "play", backGroundColor: Color(.systemBlue), maxWidth: true)
                    }
                    if (viewModel.canResumeGame) {
                        ActionButton(label: "RESUME GAME", action: {
                            do {
                                try await viewModel.resumeGame(gameId: gameId)
                            } catch {
                                print("DEBUG :: Error resuming game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "play", backGroundColor: Color(.systemBlue), maxWidth: true)
                    }
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Text("Return to game list")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    }
                    .font(.system(size: 14))
                }
                .padding()
                
            }
            .task {
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
