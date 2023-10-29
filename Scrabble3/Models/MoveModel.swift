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
    let id: String
    let gameId: String
    let createdAt: Timestamp
    let user: DBUser
    let words: [WordModel]
    let score: Int
}
