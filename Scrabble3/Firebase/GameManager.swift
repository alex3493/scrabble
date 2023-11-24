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
    
    private func activeGameCollection(includeEmails: [String]) -> Query {
        gameCollection(withCreatorEmails: includeEmails)
            .whereField(GameModel.CodingKeys.gameStatus.rawValue, in: ["running", "waiting", "suspended"])

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
    func createNewGame(creatorUser: DBUser) async throws -> GameModel {
        let document = gameCollection.document()
        let documentId = document.documentID
        
        // We need to init empty board.
        let boardMViewModel = BoardViewModel()
        
        let game = GameModel(id: documentId, createdAt: Timestamp(), creatorUser: creatorUser, lang: GameLanguage.ru, players: [
            Player(user: creatorUser, score: 0, letterRack: [])
        ], turn: 0, boardCells: boardMViewModel.cells)
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
        for playerIndex in game.players.indices {
            game.players[playerIndex].letterRack = initRack()
        }
        
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
    
    func nextTurn(gameId: String, score: Int, user: DBUser, userLetterRack: [CellModel], boardCells: [CellModel]) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        
        // Save current player letter rack.
        let playerIndex = game.players.firstIndex { $0.id == user.userId }
        guard let playerIndex = playerIndex else { return }
        game.players[playerIndex].letterRack = userLetterRack
        
        game.nextTurn(score: score, playerIndex: playerIndex)
        
        // TODO: refactor - make max score configurable.
        if let maxScore = game.players.max(by: { $0.score < $1.score })?.score {
            // print("Next turn: check for game end :: \(String(describing: maxScore)) Current turn: \(game.turn)")
            if (game.turn == 0 && maxScore >= 200) {
                // Game finished!
                game.gameStatus = .finished
            }
        }
        
        game.boardCells = boardCells
        
        guard let data = try? encoder.encode(game) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        try await gameDocument(gameId: gameId).updateData(data)
    }
    
    // Listen for active games.
    func addListenerForGames(includeEmails: [String]) -> AnyPublisher<[GameModel], Error> {
        let (publisher, listener) = activeGameCollection(includeEmails: includeEmails)
            .addListSnapshotListener(as: GameModel.self)
        
        self.gamesListener = listener
        return publisher
    }
    
    // Listen for game item updates.
    func addListenerForGame(gameId: String) -> AnyPublisher<GameModel, Error> {
        let (publisher, listener) = gameCollection.document(gameId)
            .addItemSnapshotListener(as: GameModel.self)
        
        self.gameListener = listener
        return publisher
    }
    
    func removeListenerForGames() {
        gamesListener?.remove()
    }
    
    func removeListenerForGame() {
        gameListener?.remove()
    }
    
    func initRack() -> [CellModel] {
        let letterBank = LetterBank.getAllTilesShuffled()
        
        var rack = [CellModel]()
        for pos in 0..<LetterStoreBase.size {
            rack.append(CellModel(row: -1, col: -1, pos: pos, letterTile: letterBank[pos], cellStatus: .currentMove, role: .rack))
        }
        
        return rack
    }
    
    // TODO: we can also move init board here.
}

