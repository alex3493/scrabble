//
//  MoveModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct MoveModel: Identifiable, Codable {
    var id: String
    let gameId: String
    let createdAt: Timestamp
    let user: DBUser
    let words: [WordModel]
    let score: Int
    
//    init(gameId: String, user: DBUser, words: [WordModel], score: Int) {
//        self.id = ""
//        self.gameId = gameId
//        self.createdAt = Timestamp()
//        self.user = user
//        self.words = words
//        self.score = score
//    }
//    
//    mutating func setId(id: String) {
//        self.id = id
//    }
}
