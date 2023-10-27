//
//  WordModel.swift
//  Scrabble3
//
//  Created by Alex on 26/10/23.
//

import Foundation

struct WordModel: Codable {
    let word: String
    let score: Int
    let anchorRow: Int
    let anchorCol: Int
    let direction: String
    let cells: [CellModel]
}
