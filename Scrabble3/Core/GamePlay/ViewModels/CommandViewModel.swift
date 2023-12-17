//
//  CommandViewModel.swift
//  Scrabble3
//
//  Created by Alex on 28/10/23.
//

import Foundation
import Combine
import AVFoundation

@MainActor
final class CommandViewModel: ObservableObject {
    
    @Published var boardViewModel: BoardViewModel
    @Published var rackViewModel: RackViewModel
    
    @Published var game: GameModel?
    @Published var gameMoves: [MoveModel] = []
    
    @Published var tempScores: [Int: Int] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: DBUser? = nil
    
    private var existingWords = [WordModel]()
    
    private var wordDefinitionsDict: [String: WordDefinition] = [:]
    
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
        guard game != nil else { return }
        if (confirmed) {
            rackViewModel.changeLetters(game: &game!)
            try await nextTurn(gameId: gameId)
        }
        rackViewModel.setChangeLettersMode(mode: false)
    }
    
    func validateMove(gameId: String) async {
        do {
            if await submitMove() {
                let moveWords = try boardViewModel.getMoveWords()
                
                // We can also show definitions in current move info.
//                let wordsWithDefinitions = moveWords.map { word in
//                    var withDefinition = word
//                    if let definition = wordDefinitionsDict[word.getHash()] {
//                        withDefinition.setWordInfo(definition: definition)
//                    }
//                    return withDefinition
//                }
//                
//                let wordsSummary = wordsWithDefinitions.map { ($0.word, $0.wordDefinition, $0.score) }
                
                // For current move words check we do not inject word definitions.
                let wordsSummary = moveWords.map { ($0.word, $0.wordDefinition, $0.score) }
                
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
                print("GAME LISTENER :: Game ID: \(String(describing: game?.id)) updated in command view")
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
        
        if rackViewModel.isEmpty {
            // For empty rack always pull it from game.
            rackViewModel.setRack(cells: player.letterRack)
        } else {
            // Compare current rack content with saved rack:
            let sourceLetters = player.letterRack.map { $0.letterTile?.char ?? " " }
            let targetLetters = rackViewModel.cells.map { $0.letterTile?.char ?? " " }
            
            // If only tiles order have changed there is no need to pull rack from game.
            if sourceLetters.sorted() != targetLetters.sorted() {
                rackViewModel.setRack(cells: player.letterRack)
            }
        }
    }
    
    func updateGameBoard() {
        guard let game = game else { return }
        
        boardViewModel.cells = game.boardCells
        
        Task {
            let allMoves = try await MoveManager.shared.getGameMoves(gameId: game.id).getDocuments(as: MoveModel.self)
            
            gameMoves = allMoves.sorted { lhs, rhs in
                return lhs.createdAt < rhs.createdAt
            }
            
            existingWords = gameMoves.flatMap { $0.words }
            
            if let recentMove = gameMoves.last {
                boardViewModel.highlightWords(words: recentMove.words, status: CellModel.CellStatus.moveHistory)
                
                if currentUser?.userId != recentMove.user.userId {
                    let systemSoundID: SystemSoundID = 1008
                    AudioServicesPlaySystemSound(systemSoundID)
                }
            }
        }
    }
    
    func validateMove() async throws {
        guard let game else {
            print("PANIC :: game not defined!")
            return
        }
        
        tempScores = [:]
        
        let words = try boardViewModel.getMoveWords()
        
        boardViewModel.resetCellsStatus()
        
        let hanging = boardViewModel.checkWordsConnection(words: words)
        if (hanging.count > 0) {
            boardViewModel.highlightWords(words: hanging, status: .error)
            throw ValidationError.hangingWords(words: hanging.map { $0.word })
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
        
        var invalidWords = [WordModel]()
        for word in words {
            let response = await Api.validateWord(word: word.word, lang: game.lang)
            if (response == nil || !response!.isValid) {
                invalidWords.append(word)
            } else {
                // Add word definition to dictionary for future use (on submit move).
                wordDefinitionsDict[word.getHash()] = response!.wordDefinition
            }
        }
        
        if (invalidWords.count > 0) {
            boardViewModel.highlightWords(words: invalidWords, status: .error)
            throw ValidationError.invalidWords(words: invalidWords.map { $0.word })
        }
        
        // We have a valid move here.
        let moveScore = words.reduce(0) { $0 + $1.score }
        print("Valid move - score:", moveScore)
        
        tempScores[game.turn] = moveScore

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
        
        guard let moveWords = try? boardViewModel.getMoveWords(), let currentUser = currentUser, var updatedGame = game else { return }
        
        if rackViewModel.isEmpty {
            moveScore += Constants.Game.bonusFullRackMove
        }
        
        // Inject word definitions obtained during API validation.
        let wordsWithDefinitions = moveWords.map { word in
            var withDefinition = word
            if let definition = wordDefinitionsDict[word.getHash()] {
                withDefinition.setWordInfo(definition: definition)
            }
            return withDefinition
        }
        
        try MoveManager.shared.addMove(gameId: gameId, user: currentUser, words: wordsWithDefinitions, score: moveScore, hasBonus: rackViewModel.isEmpty)
        
        // Here rack contains letters for the player who just submitted the move.
        // Fill missing tiles.
        rackViewModel.fillRack(game: &updatedGame)
        
        boardViewModel.confirmMove()
        
        tempScores = [:]
        
        // TODO: here we always have game object, so gameId parameter may be rdundant.
        try await GameManager.shared.nextTurn(gameId: gameId, score: moveScore, user: currentUser, userLetterRack: rackViewModel.cells, boardCells: boardViewModel.cells, letterBank: updatedGame.letterBank)
    }
    
    func resetMove() {
        for cell in boardViewModel.currentMoveCells {
            rackViewModel.insertLetterTileByPos(pos: 0, letterTile: cell.letterTile!, emptyPromisePos: nil)
            boardViewModel.setLetterTileByPosition(row: cell.row, col: cell.col, letterTile: nil)
        }
        
        tempScores = [:]
    }
    
    func onPerformDrop(value: CGPoint, cell drag: CellModel, boardIsLocked: Bool) {
        print("On drop", value, drag.pos, drag.row, drag.col)
        
        let rackDropCellIndex = rackViewModel.cellIndexFromPoint(value.x, value.y)
        let boardDropCellIndex = boardViewModel.cellIndexFromPoint(value.x, value.y)
        
        print("Cell indices: rack / board", rackDropCellIndex ?? "N/A", boardDropCellIndex ?? "N/A")
        
        var drop: CellModel? = nil
        
        if let rackDropCellIndex = rackDropCellIndex {
            drop = rackViewModel.cells[rackDropCellIndex]
        }
        
        if let boardDropCellIndex = boardDropCellIndex {
            drop = boardViewModel.cells[boardDropCellIndex]
        }
        
        guard let drop = drop else { return }
        
        if boardIsLocked && drop.role == .board {
            return
        }
        
        if drop.role == .board && drop.isImmutable && drop.letterTile != nil && drop.letterTile!.isAsterisk {
            if drop.letterTile!.char == drag.letterTile!.char {
                // Asterisk exchange.
                moveCell(drag: drag, drop: drop)
                // Keep cell as immutable after asterisk exchange.
                boardViewModel.setCellStatusByPosition(row: drop.row, col: drop.col, status: .immutable)
            } else {
                // Attempt to exchange for a wrong letter - nothing to do.
                return
            }
        }
        
        // Check conditions before we move cell.
        if drop.cellStatus == .empty || (!drop.isImmutable && !isReadyForLetterChange) {
            moveCell(drag: drag, drop: drop)
            
            // Only validate words if board words have changed.
            if drop.role == .board || drag.role == .board {
                // Debounce automatic validation.
                let debounce = Debounce(duration: 1)
                debounce.submit {
                    Task {
                        do {
                            try await self.validateMove()
                        } catch {
                            // We swallow exception here, later we may change it...
                            // TODO: this is not OK. We should consume this exception in model in order to update view...
                            print("On-the-fly validation failed", error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    func moveCell(drag: CellModel, drop: CellModel) {
        if (drag.role == .board && drop.role == .board) {
            // Board to board.
            boardViewModel.setLetterTileByPosition(row: drop.row, col: drop.col, letterTile: drag.letterTile!)
            if (drop.letterTile != nil) {
                boardViewModel.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: drop.letterTile!)
            } else {
                boardViewModel.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: nil)
            }
        } else if (drag.role == .rack && drop.role == .board) {
            // Rack to board.
            boardViewModel.setLetterTileByPosition(row: drop.row, col: drop.col, letterTile: drag.letterTile!)
            if (!drop.isEmpty) {
                rackViewModel.setLetterTileByPosition(pos: drag.pos, letterTile: drop.letterTile!)
            } else {
                rackViewModel.emptyCellByPosition(pos: drag.pos)
            }
        } else if (drag.role == .board && drop.role == .rack) {
            // Board to rack.
            rackViewModel.insertLetterTileByPos(pos: drop.pos, letterTile: drag.letterTile!, emptyPromisePos: nil)
            boardViewModel.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: nil)
        } else {
            // Rack to rack.
            rackViewModel.insertLetterTileByPos(pos: drop.pos, letterTile: drag.letterTile!, emptyPromisePos: drag.pos)
        }
    }
    
    private var isReadyForLetterChange: Bool {
        return rackViewModel.changeLettersMode
    }
    
    deinit {
        print("***** CommandViewModel DESTROYED")
    }
    
}
