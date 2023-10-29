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
        let game = GameModel(id: documentId, createdAt: Timestamp(), creatorUser: creatorUser, users: [creatorUser], turn: 0, scores: [0])
        
        try document.setData(from: game, merge: false, encoder: encoder)
        
        return game
    }
    
    func getGame(gameId: String) async throws -> GameModel {
        try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
    }
    
    func joinGame(gameId: String, user: DBUser) async throws {
        guard let data = try? encoder.encode(user) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        guard let game = try? await getGame(gameId: gameId) else { return }
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.users.rawValue : FieldValue.arrayUnion([data]),
            GameModel.CodingKeys.scores.rawValue : [Int](repeating: 0, count: game.users.count + 1)
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
    }
    
    func leaveGame(gameId: String, user: DBUser) async throws {
        guard let data = try? encoder.encode(user) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        guard let game = try? await getGame(gameId: gameId) else { return }
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.users.rawValue : FieldValue.arrayRemove([data]),
            GameModel.CodingKeys.scores.rawValue : [Int](repeating: 0, count: game.users.count - 1)
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
    
    func stopGame(gameId: String) async throws {
        var game = try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
        game.gameStatus = .finished
        
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

