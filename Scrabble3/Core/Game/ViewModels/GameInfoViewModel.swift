//
//  GameStartViewModel.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import Foundation
import Combine

@MainActor
final class GameInfoViewModel: ObservableObject {
    
    @Published var game: GameModel?
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: DBUser? = nil
    
    var isMeGameCreator: Bool {
        guard let game = game else { return false }
        
        return game.creatorUser.userId == currentUser?.userId
    }
    
    var isMeGamePlayer: Bool {
        guard let game = game else { return false }
        
        return game.players.contains(where: { player in
            return player.user.userId == currentUser?.userId
        })
    }
    
    var canStartGame: Bool {
        guard let game = game else { return false }
        
        return isMeGamePlayer && game.gameStatus == .waiting && game.players.count >= 2
    }
    
    var canResumeGame: Bool {
        guard let game = game else { return false }
        
        return isMeGamePlayer && game.gameStatus == .suspended && game.players.count >= 2
    }
    
    var canJoinGame: Bool {
        guard let game = game else { return false }
        
        return !isMeGamePlayer && game.gameStatus == .waiting
    }
    
    var canLeaveGame: Bool {
        guard let game = game else { return false }
        
        return isMeGamePlayer && game.gameStatus == .waiting
    }
    
    var isGameRunning: Bool {
        guard let game = game else { return false }
        
        return game.gameStatus == .running
    }
    
    var players: [Player] {
        guard let game = game else { return [] }
        return game.players
    }
    
    func addListenerForGame() {
        guard let game = game else { return }
        
        GameManager.shared.addListenerForGame(gameId: game.id)
            .sink { completion in
                
            } receiveValue: { [weak self] game in
                print("GAME LISTENER :: Game ID: \(game.id) updated in game info view")
                self?.game = game
            }
            .store(in: &cancellables)
    }
    
    func removeListenerForGame() {
        GameManager.shared.removeListenerForGame()
    }
    
    func createGame(byUser user: DBUser) async throws -> String? {
        self.game = try await GameManager.shared.createNewGame(creatorUser: user)
        
        return self.game?.id
    }
    
    func loadGame(gameId: String) async {
        self.game = try? await GameManager.shared.getGame(gameId: gameId)
    }
    
    func startGame (gameId: String) async throws {
        try await GameManager.shared.startGame(gameId: gameId)
    }
    
    func resumeGame (gameId: String) async throws {
        try await GameManager.shared.resumeGame(gameId: gameId)
    }
    
    func joinGame(gameId: String) async throws {
        guard let user = currentUser else { return }
        try await GameManager.shared.joinGame(gameId: gameId, user: user)
    }
    
    func leaveGame(gameId: String) async throws {
        guard let user = currentUser else { return }
        try await GameManager.shared.leaveGame(gameId: gameId, user: user)
    }
    
    func abortGame(gameId: String) async throws {
        guard let user = currentUser else { return }
        try await GameManager.shared.suspendGame(gameId: gameId, abort: true)
    }
    
    func deleteGame(gameId: String) async throws {
        try await GameManager.shared.deleteGame(gameId: gameId)
        MoveManager.shared.deleteMoves(gameId: gameId)
    }
    
    deinit {
        print("***** GameInfoViewModel DESTROYED")
    }
}
