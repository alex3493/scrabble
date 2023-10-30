//
//  GamePlayViewModel.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation
import Combine

@MainActor
class GamePlayViewModel: ObservableObject {
    
    private var rackViewModel = RackViewModel.shared
    private var boardViewModel = BoardViewModel.shared
    
    static var shared = GamePlayViewModel()
    
    let currentUser = AuthWithEmailViewModel.sharedCurrentUser
    
    private var existingWords = [WordModel]()
    
    @Published var gameMoves: [MoveModel] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() { }
    
    func newGame() {
        // Clean move storage.
        
    }
    
    func validateMove() async throws {
        boardViewModel.resetCellsStatus()
        let words = try boardViewModel.getMoveWords()
        
        let hanging = boardViewModel.checkWordsConnection(words: words)
        if (hanging.count > 0) {
            boardViewModel.highlightWords(words: hanging, status: .error)
            throw ValidationError.hangingWords(words: hanging)
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
            throw ValidationError.invalidWords(words: invalidWords)
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
            throw ValidationError.repeatedWords(words: repeatedWords)
        }
    }
    
    func submitMove() async -> Bool {
        do {
            try await validateMove()
            return true
        } catch(ValidationError.hangingWords /* (let words) */) {
            // TODO: show error message.
            return false
        } catch(ValidationError.invalidWords /* (let words) */) {
            // TODO: show error message.
            return false
        } catch(ValidationError.repeatedWords /* (let words) */) {
            // TODO: show error message.
            return false
        } catch(ValidationError.invalidLetterTilePosition) {
            // TODO: show error message.
            return false
        } catch {
            // Unknown error.
            return false
        }
    }
    
    func nextTurn(gameId: String) async throws {
        
        let moveScore = boardViewModel.getMoveScore()
        
        let moveWords = try? boardViewModel.getMoveWords()
        
        guard let moveWords = moveWords, let currentUser = currentUser else { return }
        
        try MoveManager.shared.addMove(gameId: gameId, user: currentUser, words: moveWords, score: moveScore)
        
        try await GameManager.shared.nextTurn(gameId: gameId, score: moveScore)
        
        boardViewModel.confirmMove()
        
        // Here rack contains letters for the player who just submitted the move.
        // Fill missing tiles.
        rackViewModel.fillRack()
    }
    
    func stopGame() {
        // Show winner.
        // Change game status.
    }
    
    func resetMove() {
        let moveCells = boardViewModel.getCurrentMoveCells()
        
        for cell in moveCells {
            rackViewModel.insertLetterTileByPos(pos: 0, letterTile: cell.letterTile!, emptyPromisePos: nil)
            boardViewModel.setLetterTileByPosition(row: cell.row, col: cell.col, letterTile: nil)
        }
    }
    
    func addListenerForMoves(gameId: String?) {
        guard let gameId = gameId else { return }
        
        MoveManager.shared.addListenerForMoves(gameId: gameId)
            .sink { completion in
                
            } receiveValue: { [weak self] moves in
                print("Game ID \(gameId) moves updated count: \(moves.count)")
                self?.gameMoves = moves
                
                if (self != nil) {
                    self!.getExistingWords(moves: moves)
                }
            }
            .store(in: &cancellables)
    }
    
    func getExistingWords(moves: [MoveModel]) {
        
        var words = [WordModel]()
        for move in moves {
            words = words + move.words
        }
        existingWords = words
        print("Existing words \(existingWords.map { $0.word }), count: \(existingWords.count)")
        
        boardViewModel.clearBoard()
        boardViewModel.setWordsToBoard(words: existingWords)
        
    }
    
}