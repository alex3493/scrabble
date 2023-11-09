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
    var players: [Player]
    var boardCells: [CellModel]
    var turn: Int = 0
    var gameStatus: GameStatus = .waiting
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case creatorUser = "creator_user"
        case players
        case boardCells = "board_cells"
        case turn
        case gameStatus = "game_status"
    }
    
    enum GameStatus: String, Codable {
        case waiting    // Waiting for players to join and start game. Once game is running we never return to this status.
        case running    // Normal game progress.
        case suspended  // Not sure: one of the users have left game play view. We may show a notice to remaining users. We also support resume game.
        case finished   // Normal game finish - with winner(s).
        case aborted    // Game aborted by one of the players. Aborted games should never change status.
    }
    
    init(id: String, createdAt: Timestamp, creatorUser: DBUser, players: [Player], turn: Int, gameStatus: GameStatus = .waiting, boardCells: [CellModel] = []) {
        self.id = id
        self.createdAt = createdAt
        self.creatorUser = creatorUser
        self.players = players
        self.boardCells = boardCells
        self.turn = turn
        self.gameStatus = gameStatus
    }
    
    mutating func nextTurn(score: Int, playerIndex: Int) {
        players[playerIndex].score += score
        turn = turn + 1
        if turn >= players.count {
            turn = 0
        }
    }
}
