//
//  GameStartView.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import SwiftUI

struct GameStartView: View {
    
    @State var gameId: String? = nil
    
    @StateObject private var viewModel = GameStartViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let errorStore = ErrorStore.shared
    
    var body: some View {
        if (viewModel.isGameRunning) {
            GamePlayView(game: viewModel.game!)
        } else {
            VStack {
                if viewModel.game != nil && gameId != nil {
                    List {
                        Section("Game") {
                            Text("Current game creator: \(viewModel.game!.creatorUser.name!)")
                            Text("Current game ID: \(viewModel.game!.id)")
                            Text("Current game status: \(viewModel.game!.gameStatus.rawValue)")
                        }
                        
                        Section("Players") {
                            ForEach(viewModel.players, id: \.self) { player in
                                Text(player.name!)
                            }
                            
                        }
                    }
                    
                    if (viewModel.isMeGameCreator()) {
                        ActionButton(label: "DELETE GAME", action: {
                            do {
                                try await viewModel.deleteGame(gameId: gameId!)
                                dismiss()
                            } catch {
                                print("DEBUG :: Error deleting game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed), maxWidth: true)
                    } else if viewModel.isMeGamePlayer() {
                        ActionButton(label: "LEAVE GAME", action: {
                            do {
                                try await viewModel.leaveGame(gameId: gameId!)
                                dismiss()
                            } catch {
                                print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: true)
                    } else {
                        ActionButton(label: "JOIN GAME", action: {
                            do {
                                try await viewModel.joinGame(gameId: gameId!)
                            } catch {
                                print("DEBUG :: Error joining game: \(error.localizedDescription)")
                                errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }, buttonSystemImage: "square.and.arrow.down", backGroundColor: Color(.systemBlue), maxWidth: true)
                    }
                    if (viewModel.canStartGame()) {
                        ActionButton(label: "START GAME", action: {
                            do {
                                try await viewModel.startGame(gameId: gameId!)
                            } catch {
                                print("DEBUG :: Error starting game: \(error.localizedDescription)")
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
                    } catch {
                        print("DEBUG :: Error creating game: \(error.localizedDescription)")
                        errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                    }
                    viewModel.addListenerForGame()
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
    GameStartView()
}
