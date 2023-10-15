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

struct GameModel: Identifiable, Codable {
    
    let id: String
    let createdAt: Timestamp
    let creatorUser: DBUser
    var users: [DBUser]
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case creatorUser = "creator_user"
        case users
    }
    
    init(id: String, createdAt: Timestamp, creatorUser: DBUser, users: [DBUser]) {
        self.id = id
        self.createdAt = createdAt
        self.creatorUser = creatorUser
        self.users = users
    }
    
    func updateItem(item: GameModel) -> GameModel {
        return GameModel(id: item.id, createdAt: item.createdAt, creatorUser: item.creatorUser, users: item.users)
    }
}

final class GameManager {
    
    static let shared = GameManager()
    private init() { }
    
    // TODO: check if we ever use it...
    private var gamesListener: ListenerRegistration? = nil
    private var gameListener: ListenerRegistration? = nil
    
    private let gameCollection = Firestore.firestore().collection("games")
    
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
        let chat = GameModel(id: documentId, createdAt: Timestamp(), creatorUser: creatorUser, users: [creatorUser])
        
        try document.setData(from: chat, merge: false, encoder: encoder)
        return chat
    }
    
    func getGame(gameId: String) async throws -> GameModel {
        try await gameDocument(gameId: gameId).getDocument(as: GameModel.self)
    }
    
    func joinGame(gameId: String, user: DBUser) async throws {
        guard let data = try? encoder.encode(user) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.users.rawValue : FieldValue.arrayUnion([data])
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
    }
    
    func leaveGame(gameId: String, user: DBUser) async throws {
        guard let data = try? encoder.encode(user) else {
            throw URLError(.cannotDecodeRawData)
        }
        
        let dict: [String:Any] = [
            GameModel.CodingKeys.users.rawValue : FieldValue.arrayRemove([data])
        ]
        
        try await gameDocument(gameId: gameId).updateData(dict)
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

