//
//  CellModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct CellModel: Codable, Hashable {
    let row: Int
    let col: Int
    let pos: Int
    var letterTile: LetterTile?
    
    var isImmutable: Bool = false
    
    var cellStatus: CellStatus = .empty
    
    enum CellStatus: String, Codable, Hashable {
        case empty
        case immutable
        case currentMove
        case checkedForLetterChange
        case error
        case moveHistory
    }
    
    var role: Role = .rack
    
    enum Role: String, Codable, Hashable {
        case board
        case rack
    }
    
    var cellBonus: Bonus = .none
    
    enum Bonus: String, Codable {
        case none
        case wordDouble
        case wordTriple
        case letterDouble
        case letterTriple
    }
    
    enum CodingKeys: String, CodingKey {
        case row
        case col
        case pos
        case letterTile = "letter_tile"
        case isImmutable = "is_immutable"
        case cellStatus = "cell_status"
        case role
        case cellBonus = "cell_bonus"
    }
    
    mutating func setTile(tile: LetterTile?)
    {
        self.letterTile = tile
    }
    
    mutating func setCellStatus(status: CellStatus) {
        cellStatus = status
    }
    
    mutating func emptyCell() {
        letterTile = nil
        cellStatus = .empty
    }
    
    var isEmpty: Bool {
        return letterTile == nil
    }
    
    func isCurrentMove() -> Bool {
        return !isImmutable && cellStatus != .empty && role == .board
    }
    
    var isCenterCell: Bool {
        // TODO: make board size configurable.
        return row == 7 && col == 7
    }
    
    func getCellScore() -> Int {
        if (isEmpty) {
            return 0
        }
        
        if (!isCurrentMove()) {
            return letterTile!.score
        }
        
        switch cellBonus {
        case .letterDouble:
            return letterTile!.score * 2
        case .letterTriple:
            return letterTile!.score * 3
        default:
            return letterTile!.score
        }
    }
    
    func getCellWordBonusK() -> Int {
        if (isEmpty || !isCurrentMove()) {
            return 1
        }
        
        switch cellBonus {
        case .wordDouble:
            return 2
        case .wordTriple:
            return 3
        default:
            return 1
        }
    }
}

extension CellModel: Transferable
{
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .cell)
    }
    
}

extension UTType {
    static var cell: UTType { UTType(exportedAs: "org.scrabble.cell") }
}

