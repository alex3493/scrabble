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
        VStack {
            if viewModel.game != nil && gameId != nil {
                List {
                    Section("Game") {
                        Text("Current game creator: \(viewModel.game!.creatorUser.name!)")
                        Text("Current game ID: \(viewModel.game!.id)")
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
                            // errorStore.showLoginAlertView(withMessage: error.localizedDescription)
                        }
                    }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed))
                } else if viewModel.isMeGamePlayer() {
                    ActionButton(label: "LEAVE GAME", action: {
                        do {
                            try await viewModel.leaveGame(gameId: gameId!)
                            dismiss()
                        } catch {
                            print("DEBUG :: Error deleting game: \(error.localizedDescription)")
                            // errorStore.showLoginAlertView(withMessage: error.localizedDescription)
                        }
                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange))
                } else {
                    ActionButton(label: "JOIN GAME", action: {
                        do {
                            try await viewModel.joinGame(gameId: gameId!)
                        } catch {
                            print("DEBUG :: Error joining game: \(error.localizedDescription)")
                            // errorStore.showLoginAlertView(withMessage: error.localizedDescription)
                        }
                    }, buttonSystemImage: "square.and.arrow.down", backGroundColor: Color(.systemBlue))
                }
            }
            
            Spacer()
            
            // TODO: add return to list controls here...
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    Text("Sign in")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
                .font(.system(size: 14))
            }
            
        }
        .task {
            if (gameId == nil) {
                await createGame()
                viewModel.addListenerForGame()
            } else {
                guard let gameId = gameId else { return }
                await viewModel.loadGame(gameId: gameId)
                viewModel.addListenerForGame()
            }
        }
    }
    
    func createGame() async {
        print("Start game create")
        guard let user = authViewModel.currentUser else { return }
        
        print ("Creating game. User: \(String(describing: user.email))")
        
        gameId = await viewModel.createGame(byUser: user)
        
        print ("Game created. Id: \(String(describing: gameId))")
        
        viewModel.addListenerForGame()
        
    }
    
    func leaveGame() {
        // TODO.
    }
}

#Preview {
    GameStartView()
}
