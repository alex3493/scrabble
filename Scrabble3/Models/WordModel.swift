//
//  WordModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation

struct WordInfo: Codable, WordDefinition {
    var term: String
    var definition: String
    var imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case term
        case definition
        case imageURL = "image_url"
    }
}

struct WordModel: Codable, Hashable, Equatable {
    static func == (lhs: WordModel, rhs: WordModel) -> Bool {
        return lhs.getHash() == rhs.getHash()
    }
    
    var word: String = ""
    
    let anchorRow: Int
    let anchorCol: Int
    
    enum WordDirection: String, Codable {
        case horizontal
        case vertical
    }
    
    let direction: WordDirection
    
    var score: Int = 0
    
    var cells: [CellModel] = []
    
    var isConnectedToExisting: Bool = false
    
    var wordDefinition: WordInfo? = nil
    
    enum CodingKeys: String, CodingKey {
        case word
        case anchorRow = "anchor_row"
        case anchorCol = "anchor_col"
        case direction
        case score
        case cells
        case isConnectedToExisting = "is_connected_to_existing"
        case wordDefinition = "word_definition"
    }
    
    var isWord: Bool {
        return cells.count > 1
    }
    
    func hash(into hasher: inout Hasher) {
        return hasher.combine(getHash())
    }
    
    func getHash() -> String {
        return "\(anchorRow)::\(anchorCol)::\(direction)::\(cells.count)"
    }
    
    func intersectsWith(word: WordModel) -> Bool {
        if (getHash() == word.getHash()) {
            // Do not count intersection with self.
            return false
        }
        
        let currentCells: Set<CellModel> = Set(cells)
        let wordCells: Set<CellModel> = Set(word.cells)
        
        let intersection = currentCells.intersection(wordCells)
        
        return !intersection.isEmpty
    }
    
    func isCellInWord(row: Int, col: Int) -> Bool {
        return cells.contains { cell in
            return cell.row == row && cell.col == col
        }
    }
    
    mutating func setWordInfo(definition: WordDefinition?) {
        guard let definition else { return }
        
        wordDefinition = WordInfo(term: definition.term, definition: definition.definition, imageURL: definition.imageURL)
    }
}
