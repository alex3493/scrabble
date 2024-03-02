//
//  GameModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum GameLanguage: String, Codable {
    case en
    case ru
    case es
}

enum GameRules: String, Codable {
    case express
    case full
    case score
}

struct GameModel: Identifiable, Codable, Equatable {
    let id: String
    let createdAt: Timestamp
    let creatorUser: DBUser
    let lang: GameLanguage
    let rules: GameRules
    var players: [Player]
    var boardCells: [CellModel]
    var letterBank: [LetterTile]
    var turn: Int = 0
    var gameStatus: GameStatus = .waiting
    var numMoves: Int = 0
    
    static func == (lhs: GameModel, rhs: GameModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case creatorUser = "creator_user"
        case lang
        case rules
        case players
        case boardCells = "board_cells"
        case letterBank = "letter_bank"
        case turn
        case gameStatus = "game_status"
        case numMoves = "num_moves"
    }
    
    enum GameStatus: String, Codable {
        case waiting    // Waiting for players to join and start game. Once game is running we never return to this status.
        case running    // Normal game progress.
        case suspended  // Not sure: one of the users have left game play view. We may show a notice to remaining users. We also support resume game.
        case finished   // Normal game finish - with winner(s).
        case aborted    // Game aborted by one of the players. Aborted games should never change status.
    }
    
    init(id: String, createdAt: Timestamp, creatorUser: DBUser, lang: GameLanguage, rules: GameRules, players: [Player], turn: Int, gameStatus: GameStatus = .waiting, boardCells: [CellModel] = [], letterBank: [LetterTile] = [], numMoves: Int = 0) {
        self.id = id
        self.createdAt = createdAt
        self.creatorUser = creatorUser
        self.lang = lang
        self.rules = rules
        self.players = players
        self.boardCells = boardCells
        self.letterBank = letterBank
        self.turn = turn
        self.gameStatus = gameStatus
        self.numMoves = numMoves
    }
    
    mutating func nextTurn(score: Int, playerIndex: Int) {
        players[playerIndex].score += score
        turn = turn + 1
        if turn >= players.count {
            turn = 0
        }
        numMoves += 1
    }
    
    mutating func initPlayerRacks() {
        for index in players.indices {
            
            guard Constants.Game.Rack.size <= letterBank.count else {
                print("DEBUG :: PANIC - not enough letter tiles for rack initialisation")
                return
            }
            
            let tiles = pullLettersFromBank(count: Constants.Game.Rack.size)
            
            var rack = [CellModel]()
            for pos in 0..<tiles.count {
                rack.append(CellModel(row: -1, col: -1, pos: pos, letterTile: tiles[pos], cellStatus: .currentMove, role: .rack))
            }
            
            players[index].letterRack = rack
        }
    }
    
    mutating func pullLettersFromBank(count: Int) -> [LetterTile] {
        var letterBank = letterBank.shuffled()
        
        let countToPull = min(count, letterBank.count)
        
        var tiles: [LetterTile] = []
        
        for _ in 0..<countToPull {
            tiles.append(letterBank.remove(at: 0))
        }
        
        self.letterBank = letterBank
        
        return tiles
    }
    
    mutating func putLettersToBank(tiles: [LetterTile]) {
        letterBank.append(contentsOf: tiles)
        
        letterBank = letterBank.shuffled()
    }
    
    var fullMoveRounds: Int? {
        guard players.count > 0 else { return nil }
        
        if turn != 0 {
            return nil
        }
        
        return numMoves / players.count
    }
    
    var partialMoveRounds: Int {
        guard players.count > 0 else { return 0 }
        
        return Int(numMoves / players.count)
    }
    
    var maxScore: Int? {
        return players.max(by: { $0.score < $1.score })?.score
    }
    
    var winners: [Player]? {
        if let maxScore = players.max(by: { $0.score < $1.score })?.score {
            let winnerPlayers = players.sorted { lhs, rhs in
                return lhs.score < rhs.score
            }
            
            return winnerPlayers.filter { player in
                return player.score == maxScore
            }
        }
        
        return nil
    }
}
