//
//  LetterTileModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation

enum Lang: String, Codable {
    case en
    case ru
    case es
}

struct LetterTile: Codable, Hashable {
    let char: String
    let score: Int
    let probability: Int
    let isAsterisk: Bool
    
    let lang: Lang
    
    enum CodingKeys: String, CodingKey {
        case char
        case score
        case probability
        case isAsterisk = "is_asterisk"
        case lang
    }
    
    var hasAsteriskChar: Bool {
        return char == "*" && isAsterisk
    }
    
}

struct LetterTileBank {
    var tiles = [LetterTile]()
    
    init(lang: Lang = .ru) {
        switch lang {
        case .en:
            self.tiles = LetterBank.lettersEn
        
        default:
            self.tiles = LetterBank.lettersRu
        
        }
    }
}


struct LetterBank {
    static let lettersEn: [LetterTile] = [
        LetterTile(char: "A", score: 1, probability: 9, isAsterisk: false, lang: .en),
        LetterTile(char: "B", score: 3, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "C", score: 3, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "D", score: 4, probability: 4, isAsterisk: false, lang: .en),
        LetterTile(char: "E", score: 1, probability: 12, isAsterisk: false, lang: .en),
        LetterTile(char: "F", score: 2, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "G", score: 3, probability: 3, isAsterisk: false, lang: .en),
        LetterTile(char: "H", score: 2, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "I", score: 1, probability: 9, isAsterisk: false, lang: .en),
        LetterTile(char: "J", score: 8, probability: 1, isAsterisk: false, lang: .en),
        LetterTile(char: "K", score: 5, probability: 1, isAsterisk: false, lang: .en),
        LetterTile(char: "L", score: 1, probability: 4, isAsterisk: false, lang: .en),
        LetterTile(char: "M", score: 2, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "N", score: 1, probability: 6, isAsterisk: false, lang: .en),
        LetterTile(char: "O", score: 1, probability: 8, isAsterisk: false, lang: .en),
        LetterTile(char: "P", score: 3, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "Q", score: 10, probability: 10, isAsterisk: false, lang: .en),
        LetterTile(char: "R", score: 1, probability: 6, isAsterisk: false, lang: .en),
        LetterTile(char: "S", score: 1, probability: 4, isAsterisk: false, lang: .en),
        LetterTile(char: "T", score: 1, probability: 6, isAsterisk: false, lang: .en),
        LetterTile(char: "U", score: 1, probability: 4, isAsterisk: false, lang: .en),
        LetterTile(char: "V", score: 4, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "W", score: 4, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "X", score: 8, probability: 1, isAsterisk: false, lang: .en),
        LetterTile(char: "Y", score: 4, probability: 2, isAsterisk: false, lang: .en),
        LetterTile(char: "Z", score: 10, probability: 1, isAsterisk: false, lang: .en),
        LetterTile(char: "*", score: 0, probability: 3, isAsterisk: true, lang: .en),
    ]
    
    static let lettersRu: [LetterTile] = [
        LetterTile(char: "А", score: 1, probability: 10, isAsterisk: false, lang: .ru),
        LetterTile(char: "Б", score: 3, probability: 3, isAsterisk: false, lang: .ru),
        LetterTile(char: "В", score: 2, probability: 5, isAsterisk: false, lang: .ru),
        LetterTile(char: "Г", score: 3, probability: 3, isAsterisk: false, lang: .ru),
        LetterTile(char: "Д", score: 2, probability: 5, isAsterisk: false, lang: .ru),
        LetterTile(char: "Е", score: 1, probability: 9, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ж", score: 5, probability: 2, isAsterisk: false, lang: .ru),
        LetterTile(char: "З", score: 5, probability: 2, isAsterisk: false, lang: .ru),
        LetterTile(char: "И", score: 1, probability: 8, isAsterisk: false, lang: .ru),
        LetterTile(char: "Й", score: 2, probability: 4, isAsterisk: false, lang: .ru),
        LetterTile(char: "К", score: 2, probability: 6, isAsterisk: false, lang: .ru),
        LetterTile(char: "Л", score: 2, probability: 4, isAsterisk: false, lang: .ru),
        LetterTile(char: "М", score: 2, probability: 5, isAsterisk: false, lang: .ru),
        LetterTile(char: "Н", score: 1, probability: 8, isAsterisk: false, lang: .ru),
        LetterTile(char: "О", score: 1, probability: 10, isAsterisk: false, lang: .ru),
        LetterTile(char: "П", score: 2, probability: 6, isAsterisk: false, lang: .ru),
        LetterTile(char: "Р", score: 2, probability: 6, isAsterisk: false, lang: .ru),
        LetterTile(char: "С", score: 2, probability: 6, isAsterisk: false, lang: .ru),
        LetterTile(char: "Т", score: 2, probability: 5, isAsterisk: false, lang: .ru),
        LetterTile(char: "У", score: 3, probability: 3, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ф", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Х", score: 5, probability: 2, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ц", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ч", score: 5, probability: 2, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ш", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Щ", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ъ", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ы", score: 5, probability: 2, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ь", score: 5, probability: 2, isAsterisk: false, lang: .ru),
        LetterTile(char: "Э", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Ю", score: 10, probability: 1, isAsterisk: false, lang: .ru),
        LetterTile(char: "Я", score: 3, probability: 3, isAsterisk: false, lang: .ru),
        LetterTile(char: "*", score: 0, probability: 5, isAsterisk: true, lang: .ru),
    ]
    
    static func getAllTilesShuffled(lang: Lang = .en) -> [LetterTile] {
        var store: [LetterTile] = [LetterTile]()
        
        LetterBank.lettersRu.forEach({ tile in
            for _ in 0...tile.probability {
                store.append(LetterTile(char: tile.char, score: tile.score, probability: tile.probability, isAsterisk: tile.isAsterisk, lang: tile.lang))
            }
        })
        
        return store.shuffled()
    }
}

