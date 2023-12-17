//
//  RackViewModel.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

@MainActor
class RackViewModel: LetterStoreBase {
    @Published var changeLettersMode: Bool = false
    
    override init(lang: GameLanguage) {
        super.init(lang: lang)
        for i in 0..<Constants.Game.Rack.size {
            let cell = CellModel(row: -1, col: -1, pos: Int(i), letterTile: nil, cellStatus: .empty, role: .rack)
            cells.append(cell)
            
            cellFrames.append(nil)
        }
    }
    
    var isEmpty: Bool {
        let nonEmpty = cells.first { $0.cellStatus != .empty }
        return nonEmpty == nil
    }
    
    func setRack(cells: [CellModel]) {
        self.cells = cells
    }
    
    func cellByPosition(pos: Int) -> CellModel {
        return cells[pos]
    }
    
    func setLetterTileByPosition(pos: Int, letterTile: LetterTile?) {
        var cell = cells[pos]
        if letterTile != nil && letterTile!.isAsterisk {
            // If we have asterisk exchange we should reset tile to pure asterisk before putting to rack.
            cell.letterTile = LetterTile(char: "*", score: 0, quantity: letterTile!.quantity, isAsterisk: true, lang: letterTile!.lang)
        } else {
            // Normal flow.
            cell.letterTile = letterTile
        }
        cell.role = .rack
        cell.cellStatus = !cell.isEmpty ? .currentMove : .empty
        cells[pos] = cell
    }
    
    func setCellStatusByPosition(pos: Int, status: CellModel.CellStatus) {
        cells[pos].setCellStatus(status: status)
    }
    
    func changeLetters(game: GameModel) -> [LetterTile] {
        let markedForChange = cells.filter({ cell in
            return cell.cellStatus == .checkedForLetterChange
        })
        
        var updatedGame = game
        
        updatedGame.putLettersToBank(tiles: markedForChange.compactMap { $0.letterTile })
        
        for cell in markedForChange {
            cells[cell.pos].letterTile = nil
        }
        
        return fillRack(game: updatedGame)
    }
    
    var hasLettersMarkedForChange: Bool {
        let markedForChange = cells.filter({ cell in
            return cell.cellStatus == .checkedForLetterChange
        })
        
        return markedForChange.count > 0
    }
    
    func clearRack() {
        for idx in cells.indices {
            emptyCellByPosition(pos: idx)
        }
    }
    
    func setChangeLettersMode(mode: Bool) {
        self.changeLettersMode = mode
        if (!mode) {
            for cell in cells {
                if (!cell.isEmpty) {
                    setCellStatusByPosition(pos: cell.pos, status: .currentMove)
                }
            }
        }
    }
    
    func fillRack(game: GameModel) -> [LetterTile] {
        let emptyCells = cells.filter({ cell in
            return cell.isEmpty
        })
        
        var game = game
        
        let tiles = game.pullLettersFromBank(count: emptyCells.count)
        
        for index in emptyCells.indices {
            if index < tiles.count {
                setLetterTileByPosition(pos: emptyCells[index].pos, letterTile: tiles[index])
            }
        }
        
        return game.letterBank
    }
    
    func emptyCellByPosition(pos: Int) {
        cells[pos].letterTile = nil
        cells[pos].cellStatus = .empty
    }
    
    func insertLetterTileByPos(pos: Int, letterTile: LetterTile, emptyPromisePos: Int?) {
        guard let emptyPos = getFirstEmptyCellIndex(fromPos: pos, emptyPromisePos: emptyPromisePos) else { return }
        
        if (emptyPromisePos != nil) {
            // When moving tiles rack-to-rack always clear "drag" cell.
            emptyCellByPosition(pos: emptyPromisePos!)
        }
        if (emptyPos == pos) {
            // Inserting to an empty position - just set tile, no need to move other tiles.
            setLetterTileByPosition(pos: emptyPos, letterTile: letterTile)
        } else if (emptyPos < pos) {
            // Shifting tiles to the left.
            for i in (emptyPos + 1...pos) {
                setLetterTileByPosition(pos: i - 1, letterTile: cells[i].letterTile)
            }
        } else {
            // Shifting tiles to the right.
            for i in (pos...emptyPos - 1).reversed() {
                setLetterTileByPosition(pos: i + 1, letterTile: cells[i].letterTile)
            }
        }
        if letterTile.isAsterisk {
            let letterTile = LetterTile(char: "*", score: 0, quantity: letterTile.quantity, isAsterisk: true, lang: letterTile.lang)
            setLetterTileByPosition(pos: pos, letterTile: letterTile)
        } else {
            setLetterTileByPosition(pos: pos, letterTile: letterTile)
        }
    }
    
    private func getFirstEmptyCellIndex(fromPos: Int, emptyPromisePos: Int?) -> Int? {
        var emptyCellIndex = cells.firstIndex(where: { cell in
            return (cell.isEmpty || emptyPromisePos == cell.pos) && cell.pos >= fromPos
        })
        if (emptyCellIndex == nil) {
            emptyCellIndex = cells.firstIndex(where: { cell in
                return (cell.isEmpty || emptyPromisePos == cell.pos) && cell.pos <= fromPos
            })
        }
        return emptyCellIndex
    }
}
