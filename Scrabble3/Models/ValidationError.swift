//
//  ValidationError.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

enum ValidationError: Error {
    case invalidLetterTilePosition(cell: String)
    case hangingWords(words: [String])
    case invalidWords(words: [String])
    case repeatedWords(words: [String])
}
