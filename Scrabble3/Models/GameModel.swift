//
//  GameModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct GameModel: Identifiable, Codable {
    
    let id: String
    let createdAt: Timestamp
    let creatorUser: DBUser
    var users: [DBUser]
    var turn: Int = 0
    var gameStatus: GameStatus = .waiting
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case creatorUser = "creator_user"
        case users
        case turn
        case gameStatus = "game_status"
    }
    
    enum GameStatus: String, Codable {
        case waiting
        case running
        case finished
    }
    
    init(id: String, createdAt: Timestamp, creatorUser: DBUser, users: [DBUser], turn: Int, gameStatus: GameStatus = .waiting) {
        self.id = id
        self.createdAt = createdAt
        self.creatorUser = creatorUser
        self.users = users
        self.turn = turn
    }
}
