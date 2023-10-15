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
    
    var body: some View {
        VStack {
            if viewModel.game != nil {
                List {
                    Section("Game") {
                        Text("Current game creator: \(viewModel.game!.creatorUser.name!)")
                        Text("Current game ID: \(viewModel.game!.id)")
                    }
                    
                    Section("Players") {
                        VStack {
                            ForEach(viewModel.players, id: \.self) { player in
                                Text("Name: \(player.name!)")
                            }
                        }
                        
                    }
                    
//                    Section {
//                        
//                    }
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
