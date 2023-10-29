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
    
    let rows: Int = 15
    let cols: Int = 15
    let size: Int = 8
    
}
