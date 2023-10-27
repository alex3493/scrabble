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
    
    func getDocuments(gameId: String) -> Query {
        return moveCollection.whereField("gameId", isEqualTo: gameId)
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
        let (publisher, listener) = getDocuments(gameId: gameId)
            .addListSnapshotListener(as: MoveModel.self)
        
        self.movesListener = listener
        return publisher
    }
    
    func removeListenerForMoves() {
        movesListener?.remove()
    }
    
}


