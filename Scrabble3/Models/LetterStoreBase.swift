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

@MainActor
class MoveCellHelper: ObservableObject {
    let rackViewModel: RackViewModel
    let boardViewModel: BoardViewModel
    
    let commandViewModel: CommandViewModel
    
    init(rackViewModel: RackViewModel, boardViewModel: BoardViewModel, commandViewModel: CommandViewModel) {
        self.rackViewModel = rackViewModel
        self.boardViewModel = boardViewModel
        self.commandViewModel = commandViewModel
    }
    
    func onPerformDrop(value: CGPoint, cell drag: CellModel, boardIsLocked: Bool) {
        print("On drop", value, drag.pos, drag.row, drag.col)
        
        let rackDropCellIndex = rackViewModel.cellIndexFromPoint(value.x, value.y)
        let boardDropCellIndex = boardViewModel.cellIndexFromPoint(value.x, value.y)
        
        print("Cell indices: rack / board", rackDropCellIndex ?? "N/A", boardDropCellIndex ?? "N/A")
        
        var drop: CellModel? = nil
        
        if let rackDropCellIndex = rackDropCellIndex {
            drop = rackViewModel.cells[rackDropCellIndex]
        }
        
        if let boardDropCellIndex = boardDropCellIndex {
            drop = boardViewModel.cells[boardDropCellIndex]
        }
        
        guard let drop = drop else { return }
        
        if boardIsLocked && drop.role == .board {
            return
        }
        
        if drop.role == .board && drop.isImmutable && drop.letterTile != nil && drop.letterTile!.isAsterisk {
            if drop.letterTile!.char == drag.letterTile!.char {
                // Asterisk exchange.
                moveCell(drag: drag, drop: drop)
            } else {
                return
            }
        }
        
        if drop.cellStatus == .empty || (!drop.isImmutable && !isReadyForLetterChange) {
            moveCell(drag: drag, drop: drop)
            
            // Only validate words if board words have changed.
            if drop.role == .board || drag.role == .board {
                // Debounce automatic validation.
                let debounce = Debounce(duration: 1)
                debounce.submit {
                    Task {
                        do {
                            try await self.commandViewModel.validateMove()
                        } catch {
                            // We swallow exception here, later we may change it...
                            // TODO: this is not OK. We should consume this exception in model in order to update view...
                            print("On-the-fly validation failed", error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    func moveCell(drag: CellModel, drop: CellModel) {
        if (drag.role == .board && drop.role == .board) {
            // Board to board.
            boardViewModel.setLetterTileByPosition(row: drop.row, col: drop.col, letterTile: drag.letterTile!)
            if (drop.letterTile != nil) {
                boardViewModel.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: drop.letterTile!)
            } else {
                boardViewModel.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: nil)
            }
        } else if (drag.role == .rack && drop.role == .board) {
            // Rack to board.
            boardViewModel.setLetterTileByPosition(row: drop.row, col: drop.col, letterTile: drag.letterTile!)
            if (!drop.isEmpty) {
                rackViewModel.setLetterTileByPosition(pos: drag.pos, letterTile: drop.letterTile!)
            } else {
                rackViewModel.emptyCellByPosition(pos: drag.pos)
            }
        } else if (drag.role == .board && drop.role == .rack) {
            // Board to rack.
            rackViewModel.insertLetterTileByPos(pos: drop.pos, letterTile: drag.letterTile!, emptyPromisePos: nil)
            boardViewModel.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: nil)
        } else {
            // Rack to rack.
            rackViewModel.insertLetterTileByPos(pos: drop.pos, letterTile: drag.letterTile!, emptyPromisePos: drag.pos)
        }
    }
    
    private var isReadyForLetterChange: Bool {
        return rackViewModel.changeLettersMode
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
