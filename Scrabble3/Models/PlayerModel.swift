//
//  PlayerModel.swift
//  Scrabble3
//
//  Created by Alex on 3/11/23.
//

import Foundation

struct Player: Codable, Identifiable {
    var id: String {
        return user.userId
    }
    
    let user: DBUser
    let score: Int
    let hasTurn: Bool
    var letterRack: [CellModel]
    
    enum CodingKeys: String, CodingKey {
        case user
        case score
        case hasTurn = "has_turn"
        case letterRack = "letter_rack"
    }
}
