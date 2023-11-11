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
    let hasBonus: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case gameId = "game_id"
        case createdAt = "created_at"
        case user
        case words
        case score
        case hasBonus = "has_bonus"
    }

}

extension Timestamp: Comparable {
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        return lhs.compare(rhs) == .orderedAscending
    }
}
