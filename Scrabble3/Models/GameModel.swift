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
    var scores: [Int]
    var gameStatus: GameStatus = .waiting
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case creatorUser = "creator_user"
        case users
        case turn
        case scores
        case gameStatus = "game_status"
    }
    
    enum GameStatus: String, Codable {
        case waiting
        case running
        case finished
    }
    
    init(id: String, createdAt: Timestamp, creatorUser: DBUser, users: [DBUser], turn: Int, scores: [Int], gameStatus: GameStatus = .waiting) {
        self.id = id
        self.createdAt = createdAt
        self.creatorUser = creatorUser
        self.users = users
        self.turn = turn
        self.scores = scores
        self.gameStatus = gameStatus
    }
    
    mutating func nextTurn(score: Int) {
        scores[turn] = scores[turn] + score
        turn = turn + 1
        if turn >= users.count {
            turn = 0
        }
    }
}
