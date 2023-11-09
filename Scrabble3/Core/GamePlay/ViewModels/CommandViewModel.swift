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
    
    @Published var boardViewModel: BoardViewModel
    @Published var rackViewModel: RackViewModel
    
    @Published var game: GameModel?
    @Published var gameMoves: [MoveModel] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: DBUser? = nil
    
    private var existingWords = [WordModel]()
    
    init(boardViewModel: BoardViewModel, rackViewModel: RackViewModel) {
        print("CommandViewModel INIT")
        
        self.boardViewModel = boardViewModel
        self.rackViewModel = rackViewModel
    }
    
    func suspendGame(gameId: String, abort: Bool) async throws {
        resetMove()
        try await GameManager.shared.suspendGame(gameId: gameId, abort: abort)
    }
    
    func setChangeLettersMode(mode: Bool) {
        resetMove()
        rackViewModel.setChangeLettersMode(mode: mode)
    }
    
    func changeLetters(gameId: String, confirmed: Bool) async throws {
        if (confirmed) {
            rackViewModel.changeLetters()
            try await nextTurn(gameId: gameId)
        }
        rackViewModel.setChangeLettersMode(mode: false)
    }
    
    func validateMove(gameId: String) async {
        do {
            if await submitMove() {
                let moveWords = try boardViewModel.getMoveWords()
                
                let wordsSummary = moveWords.map { ($0.word, $0.score) }
                
                let totalScore = moveWords.reduce(0) { $0 + $1.score }
                
                boardViewModel.moveWordsSummary = wordsSummary
                boardViewModel.moveTotalScore = totalScore
                boardViewModel.moveBonus = boardViewModel.getMoveBonus
                
                boardViewModel.moveInfoDialogPresented = true
            }
        } catch {
            print("DEBUG :: Warning: \(error.localizedDescription)")
            // TODO: interpret exception.
        }
    }
    
    func submitMove(gameId: String) async throws {
        if await submitMove() {
            try await nextTurn(gameId: gameId)
        }
    }
    
    func addListenerForGame() {
        guard let game = game else { return }
        
        GameManager.shared.addListenerForGame(gameId: game.id)
            .sink { completion in
                
            } receiveValue: { [weak self] game in
                print("GAME LISTENER :: Game ID: \(game.id) updated")
                self?.game = game
                
                self?.updatePlayerLetterRack()
                self?.updateGameBoard()
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
    
    func updateGameBoard() {
        print("Update game board on game update!")
        
        guard let game = game else { return }
        
        boardViewModel.cells = game.boardCells
    }
    
    func validateMove() async throws {
        let words = try boardViewModel.getMoveWords()
        
        boardViewModel.resetCellsStatus()
        
        let hanging = boardViewModel.checkWordsConnection(words: words)
        if (hanging.count > 0) {
            boardViewModel.highlightWords(words: hanging, status: .error)
            throw ValidationError.hangingWords(words: hanging.map { $0.word })
        }
        
        var invalidWords = [WordModel]()
        for word in words {
            let response = await Api.validateWord(word: word.word)
            if (response == nil || response!.result != "yes") {
                invalidWords.append(word)
            }
        }
        
        if (invalidWords.count > 0) {
            boardViewModel.highlightWords(words: invalidWords, status: .error)
            throw ValidationError.invalidWords(words: invalidWords.map { $0.word })
        }
        
        // Check for repeated words.
        var repeatedWords = [WordModel]()
        
        // Current move.
        var currentWordsArray = [String]()
        for word in words {
            if (currentWordsArray.firstIndex(of: word.word) != nil) {
                repeatedWords.append(word)
            } else {
                currentWordsArray.append(word.word)
            }
        }
        
        // All moves.
        var existingWordsArray = [String]()
        for existingWord in existingWords {
            existingWordsArray.append(existingWord.word)
        }
        
        for word in words {
            if (existingWordsArray.firstIndex(of: word.word) != nil) {
                repeatedWords.append(word)
            }
        }
        
        if (repeatedWords.count > 0) {
            boardViewModel.highlightWords(words: repeatedWords, status: .error)
            throw ValidationError.repeatedWords(words: repeatedWords.map { $0.word })
        }
    }
    
    func submitMove() async -> Bool {
        do {
            try await validateMove()
            return true
        } catch(ValidationError.hangingWords (let words)) {
            ErrorStore.shared.showMoveValidationErrorAlert(errorType: ValidationError.hangingWords(words: words))
            return false
        } catch(ValidationError.invalidWords (let words)) {
            ErrorStore.shared.showMoveValidationErrorAlert(errorType: ValidationError.invalidWords(words: words))
            return false
        } catch(ValidationError.repeatedWords (let words)) {
            ErrorStore.shared.showMoveValidationErrorAlert(errorType: ValidationError.repeatedWords(words: words))
            return false
        } catch(ValidationError.invalidLetterTilePosition (let char)) {
            ErrorStore.shared.showMoveValidationErrorAlert(errorType: ValidationError.invalidLetterTilePosition(cell: char))
            return false
        } catch {
            // Unknown error.
            return false
        }
    }
    
    func nextTurn(gameId: String) async throws {
        
        var moveScore = boardViewModel.getMoveScore()
        
        let moveWords = try? boardViewModel.getMoveWords()
        
        guard let moveWords = moveWords, let currentUser = currentUser else { return }
        
        if rackViewModel.isEmpty {
            // TODO: move to settings.
            moveScore += 15
        }
        
        try MoveManager.shared.addMove(gameId: gameId, user: currentUser, words: moveWords, score: moveScore, hasBonus: rackViewModel.isEmpty)
        
        // Here rack contains letters for the player who just submitted the move.
        // Fill missing tiles.
        rackViewModel.fillRack()
        
        boardViewModel.confirmMove()
        
        try await GameManager.shared.nextTurn(gameId: gameId, score: moveScore, user: currentUser, userLetterRack: rackViewModel.cells, boardCells: boardViewModel.cells)
    }
    
    func resetMove() {
        for cell in boardViewModel.currentMoveCells {
            rackViewModel.insertLetterTileByPos(pos: 0, letterTile: cell.letterTile!, emptyPromisePos: nil)
            boardViewModel.setLetterTileByPosition(row: cell.row, col: cell.col, letterTile: nil)
        }
    }
    
    func addListenerForMoves(gameId: String?) {
        guard let gameId = gameId else { return }
        
        MoveManager.shared.addListenerForMoves(gameId: gameId)
            .sink { completion in
                
            } receiveValue: { [weak self] moves in
                print("MOVE LISTENER :: Game ID \(gameId) moves updated count: \(moves.count)")
                self?.gameMoves = moves
            }
            .store(in: &cancellables)
    }
    
    func removeListenerForMoves() {
        MoveManager.shared.removeListenerForMoves()
    }
    
}
