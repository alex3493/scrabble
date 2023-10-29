//
//  ValidationError.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

enum ValidationError: Error {
    case invalidLetterTilePosition(cell: CellModel)
    case hangingWords(words: [WordModel])
    case invalidWords(words: [WordModel])
    case repeatedWords(words: [WordModel])
}
