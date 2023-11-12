//
//  GamePlayView.swift
//  Scrabble3
//
//  Created by Alex on 22/10/23.
//

import SwiftUI

struct GamePlayView: View {
    
    let game: GameModel
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    let boardViewModel: BoardViewModel
    let rackViewModel: RackViewModel
    let commandViewModel: CommandViewModel
    
    init(game: GameModel) {
        self.game = game
        
        // This is the entry point to game-play view hierarchy.
        // We create all related view models here view models here.
        self.boardViewModel = BoardViewModel()
        self.rackViewModel = RackViewModel()
        self.commandViewModel = CommandViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel)
    }
    
    var body: some View {
        GeometryReader { proxy in
            if (isLandscape(proxy.size)) {
                HStack {
                    BoardView(boardIsLocked: !hasTurn, boardViewModel: boardViewModel, rackViewModel: rackViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    RackView(boardViewModel: boardViewModel, rackViewModel: rackViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    CommandView(gameId: game.id, commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                }
            } else {
                VStack {
                    BoardView(boardIsLocked: !hasTurn, boardViewModel: boardViewModel, rackViewModel: rackViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    RackView(boardViewModel: boardViewModel, rackViewModel: rackViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    CommandView(gameId: game.id, commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                }
            }
        }
        .onAppear() {
            commandViewModel.currentUser = authViewModel.currentUser
        }
        .task {
            commandViewModel.addListenerForMoves(gameId: game.id)
        }
        .onDisappear() {
            commandViewModel.removeListenerForMoves()
        }
    }
    
    func isLandscape(_ size: CGSize) -> Bool {
        return size.width > size.height
    }
    
    var hasTurn: Bool {
        guard let user = authViewModel.currentUser else { return false }
        
        let userIndex = game.players.firstIndex { $0.user.userId == user.userId }
        
        return game.turn == userIndex
    }
}

import FirebaseFirestore
import FirebaseFirestoreSwift

struct GamePlayView_Previews: PreviewProvider {
    static var previews: some View {
        let uuid = UUID().uuidString
        let user = DBUser(userId: UUID().uuidString, email: "email@example.com", dateCreated: Date(), name: "Test user")
        GamePlayView(game: GameModel(id: uuid, createdAt: Timestamp(date: Date()), creatorUser: user, players: [
            Player(user: user, score: 0, letterRack: [])
        ], turn: 0))
    }
}

// TODO: Shortcut version is not working.
//#Preview {
//    let uuid = UUID().uuidString
//    let user = DBUser(userId: UUID().uuidString, email: "email@example.com", dateCreated: Date(), name: "Test user")
//    GamePlayView(gameId: uuid, game: GameModel(id: uuid, createdAt: Timestamp(date: Date()), creatorUser: user, users: [user], turn: 0, scores: [0]))
//}
