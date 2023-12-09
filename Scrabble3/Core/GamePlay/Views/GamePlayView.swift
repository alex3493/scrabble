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
        self.boardViewModel = BoardViewModel(lang: game.lang)
        self.rackViewModel = RackViewModel(lang: game.lang)
        self.commandViewModel = CommandViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel)
    }
    
    var body: some View {
        GeometryReader { proxy in
            if (isLandscape(proxy.size)) {
                HStack(alignment: .top) {
                    BoardView(boardIsLocked: !hasTurn, commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    VStack(alignment: .trailing) {
                        PlayerListView(viewModel: commandViewModel)
                            .padding()
                        RackView(commandViewModel: commandViewModel)
                            .environment(\.mainWindowSize, proxy.size)
                        CommandView(gameId: game.id, commandViewModel: commandViewModel)
                            // TODO: make it better!
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .environment(\.mainWindowSize, proxy.size)
                    }
                }
            } else {
                VStack {
                    BoardView(boardIsLocked: !hasTurn, commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    RackView(commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    PlayerListView(viewModel: commandViewModel)
                        .padding()
                    CommandView(gameId: game.id, commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                }
            }
        }
        .onAppear() {
            commandViewModel.currentUser = authViewModel.currentUser
            print("GamePlayView APPEARED")
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
        GamePlayView(game: GameModel(id: uuid, createdAt: Timestamp(date: Date()), creatorUser: user, lang: GameLanguage.ru, players: [
            Player(user: user, score: 0, letterRack: [])
        ], turn: 0))
    }
}

