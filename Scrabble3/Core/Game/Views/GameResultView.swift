//
//  GameResultView.swift
//  Scrabble3
//
//  Created by Alex on 12/11/23.
//

import SwiftUI

struct GameResultView: View {
    
    @StateObject private var viewModel = GameInfoViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let errorStore = ErrorStore.shared
    
    let game: GameModel
    
    @State var currentUser: DBUser? = nil
    
    var body: some View {
        VStack {
            List {
                Section("Игра") {
                    Text("\(game.creatorUser.name!): \(Utils.formatTransactionTimestamp(game.createdAt))")
                    Text("Current game status: \(game.gameStatus.rawValue)")
                }
                
                Section("Игроки") {
                    ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 12) {
                            Text(item.user.name!)
                            Spacer()
                            Text("\(item.score)")
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            if canDeleteGame {
                ActionButton(label: "УДАЛИТЬ ИГРУ", action: {
                    do {
                        try await viewModel.deleteGame(gameId: game.id)
                        dismiss()
                    } catch {
                        print("DEBUG :: Error deleting game: \(error.localizedDescription)")
                        errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                    }
                }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed), maxWidth: true)
            }
            
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
        .onAppear() {
            // print("Current user \(String(describing: authViewModel.currentUser))")
            currentUser = authViewModel.currentUser
        }
    }
    
    var canDeleteGame: Bool {
        return game.creatorUser.userId == currentUser?.userId
    }
}

import FirebaseFirestore
import FirebaseFirestoreSwift

struct GameResultView_Previews: PreviewProvider {
    static var previews: some View {
        let uuid = UUID().uuidString
        let user = DBUser(userId: UUID().uuidString, email: "email@example.com", dateCreated: Date(), name: "Test user")
        GameResultView(game: GameModel(id: uuid, createdAt: Timestamp(), creatorUser: user, players: [Player(user: user, score: 0, letterRack: [])], turn: 0))
    }
}
