//
//  LetterStoreBase.swift
//  Scrabble3
//
//  Created by Alex on 28/10/23.
//

import Foundation

@MainActor
class LetterStoreBase: ObservableObject {
    @Published var cells = [CellModel]()
    
    static let rows: Int = 15
    static let cols: Int = 15
    static let size: Int = 8
    
}
