//
//  CellView.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import SwiftUI

struct CellView: View {
    
    var cell: CellModel
    
    @StateObject private var board = BoardViewModel.shared
    @StateObject private var rack = RackViewModel.shared
    
    var body: some View {
        let cellPiece = ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(getCellFill())
            Text(!cell.isEmpty
                 ? cell.letterTile!.char
                 : " "
            ).colorInvert()
        }
        
        if (cell.cellStatus == .empty) {
            cellPiece
                .dropDestination(for: CellModel.self) { items, location in
                    let cell = items.first ?? nil
                    if (cell != nil) {
                        moveCell(drag: cell!, drop: self.cell)
                    }
                    return true
                }
        } else if (!cell.isImmutable && !isCellReadyForLetterChange) {
            cellPiece
                .draggable(cell)
                .dropDestination(for: CellModel.self) { items, location in
                    let cell = items.first ?? nil
                    if (cell != nil) {
                        moveCell(drag: cell!, drop: self.cell)
                    }
                    return true
                }
        } else if (isCellReadyForLetterChange) {
            cellPiece
                .onTapGesture {
                    rack.setCellStatusByPosition(
                        pos: cell.pos,
                        status: cell.cellStatus == .checkedForLetterChange
                        ? .currentMove
                        : .checkedForLetterChange
                    )
                }
        } else {
            cellPiece
        }
    }
    
    private func moveCell(drag: CellModel, drop: CellModel) {
        if (drag.role == .board && drop.role == .board) {
            // Board to board.
            board.setLetterTileByPosition(row: drop.row, col: drop.col, letterTile: drag.letterTile!)
            if (drop.letterTile != nil) {
                board.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: drop.letterTile!)
            } else {
                board.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: nil)
            }
        } else if (drag.role == .rack && drop.role == .board) {
            // Rack to board.
            board.setLetterTileByPosition(row: drop.row, col: drop.col, letterTile: drag.letterTile!)
            if (!drop.isEmpty) {
                rack.setLetterTileByPosition(pos: drag.pos, letterTile: drop.letterTile!)
            } else {
                rack.emptyCellByPosition(pos: drag.pos)
            }
        } else if (drag.role == .board && drop.role == .rack) {
            // Board to rack.
            rack.insertLetterTileByPos(pos: drop.pos, letterTile: drag.letterTile!, emptyPromisePos: nil)
            board.setLetterTileByPosition(row: drag.row, col: drag.col, letterTile: nil)
        } else {
            // Rack to rack.
            rack.insertLetterTileByPos(pos: drop.pos, letterTile: drag.letterTile!, emptyPromisePos: drag.pos)
        }
    }
    
    // TODO: Issue here: when cell status is updated the function below is not called. Check why?
    private func getCellFill() -> Color {
        if (cell.isEmpty) {
            switch cell.cellBonus {
            case .wordDouble:
                return .blue
            case .wordTriple:
                return .red
            case .letterDouble:
                return .green
            case .letterTriple:
                return .yellow
            default:
                return .black
            }
        } else if (cell.role == .board) {
            switch cell.cellStatus {
            case .currentMove:
                return .brown
            case .error:
                return .red
            default:
                return .black
            }
        } else {
            switch cell.cellStatus {
            case .checkedForLetterChange:
                return .red
            default:
                return .black
            }
        }
    }
    
    private var isCellReadyForLetterChange: Bool {
        return rack.changeLettersMode && cell.role == .rack && !cell.isEmpty
    }
}

#Preview {
    CellView(cell: CellModel(row: 0, col: 0, pos: -1, letterTile: nil))
}
