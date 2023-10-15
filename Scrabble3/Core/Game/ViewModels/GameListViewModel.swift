//
//  GameListViewModel.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import Foundation
import Combine

@MainActor
final class GameListViewModel: ObservableObject {
    
    @Published private(set) var games: [GameModel] = []
    private var cancellables = Set<AnyCancellable>()
    
    func addListenerForGames() {
        GameManager.shared.addListenerForGames()
            .sink { completion in
                
            } receiveValue: { [weak self] games in
                print("Game list updated")
                self?.games = games
            }
            .store(in: &cancellables)
    }
}
