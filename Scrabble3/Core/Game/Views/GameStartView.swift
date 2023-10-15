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
    
    var body: some View {
        List {
            Text("Game start view")
        }
        .task {
            if (gameId == nil) {
                await createGame()
            }
        }
    }
    
    func createGame() async {
        guard let user = authViewModel.currentUser else { return }
        
        print ("Creating game. User: \(String(describing: user.email))")
        
        let game = await viewModel.createGame(byUser: user)
        gameId = game?.id
        
        print ("Game created. Id: \(String(describing: gameId))")
        
        // TODO: add game listener here.
        
    }
    
    func leaveGame() {
        // TODO.
    }
}

#Preview {
    GameStartView()
}
