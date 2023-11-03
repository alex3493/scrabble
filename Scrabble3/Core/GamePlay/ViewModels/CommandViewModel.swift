//
//  CommandViewModel.swift
//  Scrabble3
//
//  Created by Alex on 28/10/23.
//

import Foundation
import Combine

@MainActor
final class CommandViewModel: ObservableObject {
    
    private var boardViewModel = BoardViewModel.shared
    private var rackViewModel = RackViewModel.shared
    private var gameViewModel = GamePlayViewModel.shared
    
    @Published var game: GameModel?
    private var cancellables = Set<AnyCancellable>()
    
    let currentUser = AuthWithEmailViewModel.sharedCurrentUser
    
    func suspendGame(gameId: String, abort: Bool) async throws {
        gameViewModel.resetMove()
        try await GameManager.shared.suspendGame(gameId: gameId, abort: abort)
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
    
    func validateMove(gameId: String) async {
        do {
            if await gameViewModel.submitMove() {
                let moveWords = try boardViewModel.getMoveWords()
                
                let wordsSummary = moveWords.map { ($0.word, $0.score) }
                
                let totalScore = moveWords.reduce(0) { $0 + $1.score }
                
                boardViewModel.moveWordsSummary = wordsSummary
                boardViewModel.moveTotalScore = totalScore
                
                boardViewModel.moveInfoDialogPresented = true
            }
        } catch {
            print("DEBUG :: Warning: \(error.localizedDescription)")
            // TODO: interpret exception.
        }
    }
    
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
                
                self?.updatePlayerLetterRack()
            }
            .store(in: &cancellables)
    }
    
    func loadGame(gameId: String?) async {
        guard let gameId = gameId else { return }
        self.game = try? await GameManager.shared.getGame(gameId: gameId)
    }
    
    func updatePlayerLetterRack() {
        guard let game = game, let user = currentUser else { return }
        
        let player = game.players.first { $0.id == user.userId }
        
        guard let player = player else { return }
        
        rackViewModel.setRack(cells: player.letterRack)
    }
    
}
