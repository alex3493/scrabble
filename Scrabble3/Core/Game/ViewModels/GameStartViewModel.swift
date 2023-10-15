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
    
    func createGame(byUser user: DBUser) async -> GameModel? {
        try? await GameManager.shared.createNewGame(creatorUser: user)
    }
}
