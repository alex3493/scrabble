//
//  CommandViewModel.swift
//  Scrabble3
//
//  Created by Alex on 28/10/23.
//

import Foundation

struct Player {
    let id: String
    let name: String
    let score: Int
    let hasTurn: Bool
}


@MainActor
final class CommandViewModel: ObservableObject {
    
    func getPlayersList(gameId: String) async -> [Player] {
        guard let game = try? await GameManager.shared.getGame(gameId: gameId) else { return [] }
        
        var result = [Player]()
        
        for (index, user) in game.users.enumerated() {
            result.append(Player(id: user.id, name: user.name!, score: game.scores[index], hasTurn: game.turn == index))
        }
        
        return result
    }
    
    func stopGame(gameId: String) async throws {
        try await GameManager.shared.stopGame(gameId: gameId)
    }
    
}
