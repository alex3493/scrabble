//
//  GameManager.swift
//  Scrabble3
//
//  Created by Alex on 14/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

final class GameManager {
    
    static let shared = GameManager()
    private init() { }
    
    // Just in case we need explicit listener removal.
    private var gamesListener: ListenerRegistration? = nil
    private var gameListener: ListenerRegistration? = nil
    
    private let gameCollection = Firestore.firestore().collection("games")
    
    private func activeGameCollection(includeEmails: [String], lang: GameLanguage) -> Query {
        gameCollection(withCreatorEmails: includeEmails)
            .whereField(GameModel.CodingKeys.gameStatus.rawValue, in: ["running", "waiting", "suspended"])
            .whereField(GameModel.CodingKeys.lang.rawValue, isEqualTo: lang.rawValue)
        
    }
    
    private func archivedGameCollection(includeEmails: [String]) -> Query {
        gameCollection(withCreatorEmails: includeEmails)
            .whereField(GameModel.CodingKeys.gameStatus.rawValue, in: ["finished", "aborted"])
    }
    
    private func gameCollection(withCreatorEmails includeEmails: [String]) -> Query {
        // TODO: if includeEmails is empty we should return empty query (check how to do it)...
        let creatorUserEmailField = "\(GameModel.CodingKeys.creatorUser.rawValue).\(DBUser.CodingKeys.email.rawValue)"
        
        var emails = includeEmails
        if emails.count == 0 {
            // For now - quick hack, just make sure we have empty result set.
            emails.append("")
        }
        
        return gameCollection
            .order(by: creatorUserEmailField, descending: false)
            .whereField(creatorUserEmailField, in: emails)
    }
    
    func getArchivedGames(limit: Int, includeEmails: [String], afterDocument: DocumentSnapshot?) async throws -> (items: [GameModel], lastDocument: DocumentSnapshot?) {
        
        return try await archivedGameCollection(includeEmails: includeEmails)
            .order(by: GameModel.CodingKeys.createdAt.rawValue, descending: true)
            .limit(to: limit)
            .startOptionally(afterDocument: afterDocument)
            .getDocumentsWithSnapshot(as: GameModel.self)
    }
    
    private func gameDocument(gameId: String) -> DocumentReference {
        return gameCollection.document(gameId)
    }
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    @MainActor
    func createNewGame(creatorUser: DBUser, lang: GameLanguage, rules: GameRules) async throws -> GameModel {
        let document = gameCollection.document()
        let documentId = document.documentID
        
        // We need to init empty board.
        let boardMViewModel = BoardViewModel(lang: lang)
        
        // We init new letter tile bank.
        let letterBank = LetterBank.getAllTilesShuffled(lang: lang)
        
        let game = GameModel(id: documentId, createdAt: Timestamp(), creatorUser: creatorUser, lang: lang, rules: rules, players: [
            Player(user: creatorUser, score: 0, letterRack: [])
        ], turn: 0, boardCells: boardMViewModel.cells, letterBank: letterBank, numMoves: 0)
        try document.setData(from: game, merge: false, encoder: encoder)
        
        return game
    }
    
    func getGame(gameId: String) async throws -> GameModel {
        try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
    }
    
    func joinGame(gameId: String, user: DBUser) async throws {
        let player = Player(user: user, score: 0, letterRack: [])
        
        guard let data = try? encoder.encode(player) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        guard let game = try? await getGame(gameId: gameId) else { return }
        
        // Never join running or stopped game.
        guard game.gameStatus == .waiting else { return }
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.players.rawValue : FieldValue.arrayUnion([data])
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
    }
    
    func leaveGame(gameId: String, user: DBUser) async throws {
        guard let game = try? await getGame(gameId: gameId) else { return }
        
        let player = game.players.first {
            $0.id == user.userId
        }
        
        guard let data = try? encoder.encode(player) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        // Never leave running or stopped game.
        guard game.gameStatus == .waiting else { return }
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.players.rawValue : FieldValue.arrayRemove([data])
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
    }
    
    func deleteGame(gameId: String) async throws {
        try await gameDocument(gameId: gameId).delete()
    }
    
    func startGame(gameId: String) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        
        guard game.gameStatus == .waiting else { return }
        
        game.gameStatus = .running
        
        // Set letter racks for each player.
        game.initPlayerRacks()
        
        guard let data = try? encoder.encode(game) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        try await gameDocument(gameId: gameId).updateData(data)
    }
    
    func resumeGame(gameId: String) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        
        guard game.gameStatus == .suspended else { return }
        
        game.gameStatus = .running
        
        guard let data = try? encoder.encode(game) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        try await gameDocument(gameId: gameId).updateData(data)
    }
    
    func suspendGame(gameId: String, abort: Bool) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        game.gameStatus = abort ? .aborted : .suspended
        
        guard let data = try? encoder.encode(game) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        try await gameDocument(gameId: gameId).updateData(data)
    }
    
    // TODO: refactor - we should use game model as parameter, not gameId!
    func nextTurn(gameId: String, score: Int, user: DBUser, userLetterRack: [CellModel], boardCells: [CellModel], letterBank: [LetterTile]) async throws {
        
        // TODO: there should be no need to load game.
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        
        // Save current player letter rack.
        let playerIndex = game.players.firstIndex { $0.id == user.userId }
        guard let playerIndex = playerIndex else { return }
        game.players[playerIndex].letterRack = userLetterRack
        
        game.nextTurn(score: score, playerIndex: playerIndex)
        
        game.boardCells = boardCells
        
        game.letterBank = letterBank
        
        if try await isGameFinished(game: game) {
            game.gameStatus = .finished
            
            print("Game finished due to \(game.rules.rawValue) rule")
        }
        
        guard let data = try? encoder.encode(game) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        try await gameDocument(gameId: gameId).updateData(data)
    }
    
    // TODO: refactor - move limits to Constants.
    func isGameFinished(game: GameModel) async throws -> Bool {
        switch game.rules {
        case .express:
            return (game.fullMoveRounds ?? 0) >= 6
        case .full:
            if game.fullMoveRounds != nil {
                let latestMoves = try await MoveManager.shared.getGameMoves(gameId: game.id)
                    .limit(to: 3 * game.players.count).getDocuments(as: MoveModel.self)
                if latestMoves.count == 3 * game.players.count {
                    // We have at least 3 latest moves be each player.
                    let totalScore = latestMoves.map({ $0.score }).reduce(0, +)
                    // No scoring - finish the game.
                    if totalScore == 0 {
                        return true
                    }
                }
                return game.letterBank.count == 0
            }
            return false
        case .score:
            if game.fullMoveRounds != nil {
                if let maxScore = game.players.max(by: { $0.score < $1.score })?.score {
                    if maxScore >= 200 {
                        return true
                    }
                }
            }
            return false
        }
    }
    
    // Listen for active games.
    func addListenerForGames(includeEmails: [String], lang: GameLanguage) -> AnyPublisher<[GameModel], Error> {
        let (publisher, listener) = activeGameCollection(includeEmails: includeEmails, lang: lang)
            .addListSnapshotListener(as: GameModel.self)
        
        self.gamesListener = listener
        return publisher
    }
    
    // Listen for game item updates.
    func addListenerForGame(gameId: String) -> AnyPublisher<GameModel?, Error> {
        let (publisher, listener) = gameCollection.document(gameId)
            .addItemSnapshotListener(as: GameModel?.self)
        
        self.gameListener = listener
        return publisher
    }
    
    func removeListenerForGames() {
        gamesListener?.remove()
    }
    
    func removeListenerForGame() {
        gameListener?.remove()
    }
    
    func initRack(game: inout GameModel) -> [CellModel] {
        let letterBank = game.letterBank.shuffled()
        
        guard Constants.Game.Rack.size <= letterBank.count else {
            print("DEBUG :: PANIC - not enought letter tiles for rack initialisation")
            return []
        }
        
        var rack = [CellModel]()
        for pos in 0..<Constants.Game.Rack.size {
            rack.append(CellModel(row: -1, col: -1, pos: pos, letterTile: letterBank[pos], cellStatus: .currentMove, role: .rack))
        }
        
        // Update game letter bank - remove used tiles.
        game.letterBank = Array(game.letterBank[Constants.Game.Rack.size...])
        
        return rack
    }
    
    // TODO: we can also move init board here.
}

