//
//  GameStartViewModel.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import Foundation
import Combine

@MainActor
final class GameStartViewModel: ObservableObject {
    
    @Published var game: GameModel?
    private var cancellables = Set<AnyCancellable>()
    
    let currentUser = AuthWithEmailViewModel.shared.currentUser

    func isMeGameCreator() -> Bool {
        guard let game = game else { return false }
        
        return game.creatorUser.userId == AuthWithEmailViewModel.shared.currentUser?.userId
    }
    
    func isMeGamePlayer() -> Bool {
        guard let game = game else { return false }
        
        return game.users.contains(where: { user in
            return user.userId == AuthWithEmailViewModel.shared.currentUser?.userId
        })
    }
    
    var players: [DBUser] {
        guard let game = game else { return [] }
        return game.users
    }
    
    func addListenerForGame() {
        guard let game = game else { return }
        
        GameManager.shared.addListenerForGame(gameId: game.id)
            .sink { completion in
                
            } receiveValue: { [weak self] game in
                print("Game ID: \(game.id) updated")
                self?.game = game
            }
            .store(in: &cancellables)
    }
    
//    func removeListenerForGame() {
//        GameManager.shared.removeListenerForGame()
//    }
    
    func createGame(byUser user: DBUser) async -> String? {
        self.game = try? await GameManager.shared.createNewGame(creatorUser: user)
        return self.game?.id
    }
    
    func loadGame(gameId: String) async {
        self.game = try? await GameManager.shared.getGame(gameId: gameId)
    }
    
    func joinGame(gameId: String) async throws {
        guard let user = AuthWithEmailViewModel.shared.currentUser else { return }
        try await GameManager.shared.joinGame(gameId: gameId, user: user)
    }
    
    func leaveGame(gameId: String) async throws {
        guard let user = AuthWithEmailViewModel.shared.currentUser else { return }
        try await GameManager.shared.leaveGame(gameId: gameId, user: user)
    }
    
    func deleteGame(gameId: String) async throws {
        try await GameManager.shared.deleteGame(gameId: gameId)
    }
}
