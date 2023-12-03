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
            cell.letterTile = LetterTile(char: "*", score: 0, probability: letterTile!.probability, isAsterisk: true, lang: letterTile!.lang)
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
    
    func changeLetters() {
        let markedForChange = cells.filter({ cell in
            return cell.cellStatus == .checkedForLetterChange
        })
        
        for cell in markedForChange {
            cells[cell.pos].letterTile = nil
        }
        
        fillRack()
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
    
    func initRack() {
        clearRack()
        fillRack()
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
    
    func fillRack() {
        let letterBank = LetterBank.getAllTilesShuffled(lang: lang)
        
        for cell in cells {
            if (cell.isEmpty) {
                setLetterTileByPosition(pos: cell.pos, letterTile: letterBank[cell.pos])
            }
        }
    }
    
    func exportRackTiles() -> [LetterTile] {
        var exported: [LetterTile] = []
        
        cells.forEach({ cell in
            if (!cell.isEmpty) {
                exported.append(cell.letterTile!)
            }
        })
        
        return exported
    }
    
    func importRackTiles(letterTiles: [LetterTile]) {
        clearRack()
        for idx in letterTiles.indices {
            cells[idx].setTile(tile: letterTiles[idx])
            cells[idx].cellStatus = .currentMove
        }
        fillRack()
    }
    
    func emptyCellByPosition(pos: Int) {
        cells[pos].letterTile = nil
        cells[pos].cellStatus = .empty
    }
    
    func insertLetterTileByPos(pos: Int, letterTile: LetterTile, emptyPromisePos: Int?) {
        let emptyPos = getFirstEmptyCellIndex(fromPos: pos, emptyPromisePos: emptyPromisePos)
        
        if (emptyPos != nil) {
            if (emptyPromisePos != nil) {
                // When moving tiles rack-to-rack always clear "drag" cell.
                emptyCellByPosition(pos: emptyPromisePos!)
            }
            if (emptyPos == pos) {
                // Inserting to an empty position - just set tile, no need to move other tiles.
                setLetterTileByPosition(pos: emptyPos!, letterTile: letterTile)
            } else if (emptyPos! < pos) {
                // Shifting tiles to the left.
                for i in (emptyPos! + 1...pos) {
                    setLetterTileByPosition(pos: i - 1, letterTile: cells[i].letterTile)
                }
            } else {
                // Shifting tiles to the right.
                for i in (pos...emptyPos! - 1).reversed() {
                    setLetterTileByPosition(pos: i + 1, letterTile: cells[i].letterTile)
                }
            }
            if letterTile.isAsterisk {
                let letterTile = LetterTile(char: "*", score: 0, probability: letterTile.probability, isAsterisk: true, lang: letterTile.lang)
                setLetterTileByPosition(pos: pos, letterTile: letterTile)
            } else {
                setLetterTileByPosition(pos: pos, letterTile: letterTile)
            }
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
