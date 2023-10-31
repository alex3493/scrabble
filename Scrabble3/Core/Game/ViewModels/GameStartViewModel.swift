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
    
    let currentUser = AuthWithEmailViewModel.sharedCurrentUser
    
    func isMeGameCreator() -> Bool {
        guard let game = game else { return false }
        
        return game.creatorUser.userId == currentUser?.userId
    }
    
    func isMeGamePlayer() -> Bool {
        guard let game = game else { return false }
        
        return game.users.contains(where: { user in
            return user.userId == currentUser?.userId
        })
    }
    
    func canStartGame() -> Bool {
        guard let game = game else { return false }
        
        return isMeGamePlayer() && game.users.count >= 2
    }
    
    var isGameRunning: Bool {
        guard let game = game else { return false }
        
        return game.gameStatus == .running
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
    
    func createGame(byUser user: DBUser) async throws -> String? {
        self.game = try await GameManager.shared.createNewGame(creatorUser: user)
        
        addListenerForGame()
        
        return self.game?.id
    }
    
    func loadGame(gameId: String) async {
        self.game = try? await GameManager.shared.getGame(gameId: gameId)
    }
    
    func startGame (gameId: String) async throws {
        try await GameManager.shared.startGame(gameId: gameId)
    }
    
    func joinGame(gameId: String) async throws {
        guard let user = currentUser else { return }
        try await GameManager.shared.joinGame(gameId: gameId, user: user)
    }
    
    func leaveGame(gameId: String) async throws {
        guard let user = currentUser else { return }
        try await GameManager.shared.leaveGame(gameId: gameId, user: user)
    }
    
    func deleteGame(gameId: String) async throws {
        try await GameManager.shared.deleteGame(gameId: gameId)
    }
}
