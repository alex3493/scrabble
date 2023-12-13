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

enum DragState {
    case inactive
    case dragging(translation: CGSize, selectedItem: CellModel)
    
    var translation: CGSize {
        switch self {
        case .inactive:
            return .zero
        case .dragging(let translation, _):
            return translation
        }
    }
    
    var selectedItem: CellModel? {
        switch self {
        case .inactive:
            return nil
        case .dragging(_, let selectedItem):
            return selectedItem
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .dragging:
            return true
        case .inactive:
            return false
        }
    }
    
    func isDraggingFromRow(row: Int) -> Bool {
        guard let item = selectedItem else { return false }
        
        return item.row == row
    }
    
    func isDraggingCell(cell: CellModel) -> Bool {
        guard let item = selectedItem else { return false }
        
        return item == cell
    }
    
    func cellTranslation(cell: CellModel) -> CGSize {
        if isDraggingCell(cell: cell) {
            return translation
        }
        
        return .zero
    }
    
}
