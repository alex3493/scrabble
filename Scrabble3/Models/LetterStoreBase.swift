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
    
    let lang: GameLanguage
    
    init(lang: GameLanguage) {
        self.lang = lang
    }
    
    var cellFrames: [CGRect?] = []
    
    func setFrame(index: Int, frame: CGRect?) {
        self.cellFrames[index] = frame
    }
    
    func cellIndexFromPoint(_ x: CGFloat, _ y: CGFloat) -> Int? {
        
        return cellFrames.firstIndex { frame in
            guard let frame = frame else { return false }
            
            return x > frame.minX && x < frame.maxX && y > frame.minY && y < frame.maxY
        }
    }
    
}
