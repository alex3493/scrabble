//
//  MoveManager.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

final class MoveManager {
    
    static let shared = MoveManager()
    private init() { }
    
    private var movesListener: ListenerRegistration? = nil
    
    private let moveCollection = Firestore.firestore().collection("moves")
    
    func getGameMoves(gameId: String) -> Query {
        return moveCollection.whereField(MoveModel.CodingKeys.gameId.rawValue, isEqualTo: gameId)
    }
    
    func addMove(gameId: String, user: DBUser, words: [WordModel], score: Int) throws {
        let document = moveCollection.document()
        let documentId = document.documentID
        
        let move = MoveModel(id: documentId, gameId: gameId, createdAt: Timestamp(), user: user, words: words, score: score)
        
        try document.setData(from: move, merge: false, encoder: encoder)
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
    
    func addListenerForMoves(gameId: String) -> AnyPublisher<[MoveModel], Error> {
        let (publisher, listener) = getGameMoves(gameId: gameId)
            .addListSnapshotListener(as: MoveModel.self)
        
        self.movesListener = listener
        return publisher
    }
    
    func removeListenerForMoves() {
        movesListener?.remove()
    }
    
}


