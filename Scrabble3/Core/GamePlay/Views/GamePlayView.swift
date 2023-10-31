//
//  GamePlayView.swift
//  Scrabble3
//
//  Created by Alex on 22/10/23.
//

import SwiftUI

struct GamePlayView: View {
    
    let gameId: String?
    
    let game: GameModel
    
    @StateObject private var viewModel = GamePlayViewModel.shared
    
    var body: some View {
        if let gameId = gameId {
            GeometryReader { proxy in
                if (isLandscape(proxy.size)) {
                    HStack {
                        BoardView(boardIsLocked: !hasTurn)
                            .environment(\.mainWindowSize, proxy.size)
                        RackView()
                            .environment(\.mainWindowSize, proxy.size)
                        CommandView(gameId: gameId)
                            .environment(\.mainWindowSize, proxy.size)
                    }
                } else {
                    VStack {
                        BoardView(boardIsLocked: !hasTurn)
                            .environment(\.mainWindowSize, proxy.size)
                        RackView()
                            .environment(\.mainWindowSize, proxy.size)
                        CommandView(gameId: gameId)
                            .environment(\.mainWindowSize, proxy.size)
                    }
                }
            }
            .task {
                viewModel.addListenerForMoves(gameId: gameId)
            }
            .onDisappear() {
                viewModel.removeListenerForMoves()
            }
        }
    }
    
    func isLandscape(_ size: CGSize) -> Bool {
        return size.width > size.height
    }
    
    var hasTurn: Bool {
        guard let user = viewModel.currentUser else { return false }
        
        let userIndex = game.users.firstIndex { $0.userId == user.userId }
        
        return game.turn == userIndex
    }
}

import FirebaseFirestore
import FirebaseFirestoreSwift

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        let uuid = UUID().uuidString
        let user = DBUser(userId: UUID().uuidString, email: "email@example.com", dateCreated: Date(), name: "Test user")
        GamePlayView(gameId: uuid, game: GameModel(id: uuid, createdAt: Timestamp(date: Date()), creatorUser: user, users: [user], turn: 0, scores: [0]))
    }
}

// TODO: Shortcut version is not working.
//#Preview {
//    let uuid = UUID().uuidString
//    let user = DBUser(userId: UUID().uuidString, email: "email@example.com", dateCreated: Date(), name: "Test user")
//    GamePlayView(gameId: uuid, game: GameModel(id: uuid, createdAt: Timestamp(date: Date()), creatorUser: user, users: [user], turn: 0, scores: [0]))
//}
