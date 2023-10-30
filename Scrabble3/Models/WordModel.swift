//
//  WordModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation

struct WordModel: Codable, Hashable {
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
    
    enum CodingKeys: String, CodingKey {
        case word
        case anchorRow = "anchor_row"
        case anchorCol = "anchor_col"
        case direction
        case score
        case cells
        case isConnectedToExisting = "is_connected_to_existing"
    }
    
    var isWord: Bool {
        return word.count > 1
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
}
