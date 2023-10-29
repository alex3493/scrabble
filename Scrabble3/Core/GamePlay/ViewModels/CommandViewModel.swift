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
    
    private var rackViewModel = RackViewModel.shared
    // private var boardViewModel = BoardViewModel.shared
    
    private var gameViewModel = GamePlayViewModel.shared
    
    
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
    
    func setChangeLettersMode(mode: Bool) {
        gameViewModel.resetMove()
        rackViewModel.setChangeLettersMode(mode: mode)
    }
    
    func changeLetters(confirmed: Bool) {
        if (confirmed) {
            rackViewModel.changeLetters()
            gameViewModel.nextTurn()
        }
        rackViewModel.setChangeLettersMode(mode: false)
    }
    
    // TODO: We have to get all-users' previous moves words.
    func submitMove() async {
        if await gameViewModel.submitMove(existingWords: []) {
            gameViewModel.nextTurn()
        }
    }
    
}
