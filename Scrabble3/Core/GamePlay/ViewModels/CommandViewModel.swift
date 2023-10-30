//
//  CommandViewModel.swift
//  Scrabble3
//
//  Created by Alex on 28/10/23.
//

import Foundation
import Combine

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
    
    @Published var game: GameModel?
    private var cancellables = Set<AnyCancellable>()
    
    func stopGame(gameId: String) async throws {
        try await GameManager.shared.stopGame(gameId: gameId)
    }
    
    func setChangeLettersMode(mode: Bool) {
        gameViewModel.resetMove()
        rackViewModel.setChangeLettersMode(mode: mode)
    }
    
    func changeLetters(gameId: String, confirmed: Bool) async throws {
        if (confirmed) {
            rackViewModel.changeLetters()
            try await gameViewModel.nextTurn(gameId: gameId)
        }
        rackViewModel.setChangeLettersMode(mode: false)
    }
    
    // TODO: We have to get all-users' previous moves words.
    func submitMove(gameId: String) async throws {
        if await gameViewModel.submitMove() {
            try await gameViewModel.nextTurn(gameId: gameId)
        }
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
    
    func loadGame(gameId: String?) async {
        guard let gameId = gameId else { return }
        self.game = try? await GameManager.shared.getGame(gameId: gameId)
    }
    
}
