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
    
    // TODO: add waiting games collection property (.whereField stuff)
    
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
    
    func createNewGame(creatorUser: DBUser) async throws -> GameModel {
        let document = gameCollection.document()
        let documentId = document.documentID
        let game = GameModel(id: documentId, createdAt: Timestamp(), creatorUser: creatorUser, players: [
            Player(user: creatorUser, score: 0, hasTurn: true, letterRack: [])
        ], turn: 0, scores: [0])
        
        try document.setData(from: game, merge: false, encoder: encoder)
        
        return game
    }
    
    func getGame(gameId: String) async throws -> GameModel {
        try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
    }
    
    func joinGame(gameId: String, user: DBUser) async throws {
        let player = Player(user: user, score: 0, hasTurn: false, letterRack: [])
        
        guard let data = try? encoder.encode(player) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        guard var game = try? await getGame(gameId: gameId) else { return }
        
        // Never join running or stopped game.
        guard game.gameStatus == .waiting else { return }
        
        game.scores.append(0)
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.players.rawValue : FieldValue.arrayUnion([data]),
            GameModel.CodingKeys.scores.rawValue : game.scores
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
    }
    
    func leaveGame(gameId: String, user: DBUser) async throws {
        guard var game = try? await getGame(gameId: gameId) else { return }
        
        let player = game.players.first {
            $0.user.userId == user.userId
        }
        
        guard let data = try? encoder.encode(player) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        // Never leave running or stopped game.
        guard game.gameStatus == .waiting else { return }
        
        game.scores.removeLast()
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.players.rawValue : FieldValue.arrayRemove([data]),
            GameModel.CodingKeys.scores.rawValue : game.scores
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
    }
    
    func deleteGame(gameId: String) async throws {
        try await gameDocument(gameId: gameId).delete()
    }
    
    func startGame(gameId: String) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
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
    
    func nextTurn(gameId: String, score: Int) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        game.nextTurn(score: score)
        
        if let maxScore = game.scores.max() {
            print("Next turn: check for game end :: \(String(describing: maxScore)) Current turn: \(game.turn)")
            if (game.turn == 0 && maxScore >= 200) {
                // Game finished!
                var winners = [Player]()
                for (index, score) in game.scores.enumerated() {
                    if score >= maxScore {
                        winners.append(game.players[index])
                    }
                }
                
                print("Game winners: \(winners)")
                game.gameStatus = .finished
            }
        }
        
        guard let data = try? encoder.encode(game) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        try await gameDocument(gameId: gameId).updateData(data)
    }
    
    func addListenerForGames() -> AnyPublisher<[GameModel], Error> {
        let (publisher, listener) = gameCollection
            .addListSnapshotListener(as: GameModel.self)
        
        self.gamesListener = listener
        return publisher
    }
    
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
    
    
}

