//
//  CellView.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import SwiftUI

struct CellView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var cell: CellModel
    
    var boardIsLocked: Bool
    
    @StateObject private var commandViewModel: CommandViewModel
    
    @StateObject private var board: BoardViewModel
    @StateObject private var rack: RackViewModel
    
    init(cell: CellModel, boardIsLocked: Bool, commandViewModel: CommandViewModel) {
        self.cell = cell
        self.boardIsLocked = boardIsLocked
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _board = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rack = StateObject(wrappedValue: commandViewModel.rackViewModel)
    }
    
    var body: some View {
        let cellPiece = ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(cell.isEmpty && cell.isCenterCell ? .gray : cellFill)
            if showAsterisk {
                ZStack {
                    HStack {
                        // Push asterisk to right.
                        Spacer()
                        VStack {
                            Text("*")
                                .padding(.trailing, 4)
                            // Push asterisk to top.
                            Spacer()
                        }
                    }
                    Text(!cell.isEmpty
                         ? cell.letterTile!.char
                         : " "
                    )
                }
                .colorInvert()
                .font(.system(size: idealCellSize / 2))
                // TODO: Make it better!
                .frame(width: idealCellSize, height: idealCellSize)
            } else {
                Text(!cell.isEmpty
                     ? cell.letterTile!.char
                     : " "
                )
                .font(.system(size: idealCellSize / 2))
                .colorInvert()
            }
        }
        if !boardIsLocked {
            if (cell.cellStatus == .empty) {
                // Empty tile - can accept moves.
                cellPiece
                    .onDrop(of: [.text], delegate: CellDropDelegate(drop: cell, viewModel: self))
            } else if (!cell.isImmutable && !isCellReadyForLetterChange) {
                // Current move board or rack tiles - free move on board, in rack and between board and rack.
                cellPiece
                    .onDrag {
                        NSItemProvider(object: NSString(string: cell.fingerprint))
                    }
                    .onDrop(of: [.text], delegate: CellDropDelegate(drop: cell, viewModel: self))
            } else if cell.isImmutable && cell.role == .board && cell.letterTile != nil && cell.letterTile!.isAsterisk {
                // Exchange asterisk on board (rack --> board move).
                cellPiece
                    .onDrop(of: [.text], delegate: CellDropDelegate(drop: cell, viewModel: self))
            } else if (isCellReadyForLetterChange) {
                // Check tiles for letter change action.
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
        } else {
            cellPiece
                .onTapGesture {
                    print("Board cell clicked", cell.row, cell.col)
                }
        }
    }
    
    @MainActor
    func moveCell(drag: CellModel, drop: CellModel) {
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
    
    private var cellFill: Color {
        if cell.isEmpty {
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
        } else if cell.role == .board {
            switch cell.cellStatus {
            case .currentMove:
                return .brown
            case .error:
                return .red
            case .moveHistory:
                return .gray
            default:
                return .black
            }
        } else if cell.role == .rack && rack.changeLettersMode && cell.cellStatus != .checkedForLetterChange {
            return .gray
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
    
    private var showAsterisk: Bool {
        guard let tile = cell.letterTile else { return false }
        
        return tile.isAsterisk && !tile.hasAsteriskChar
    }
    
    var idealCellSize: CGFloat {
        return (min(mainWindowSize.width, mainWindowSize.height) - 40) / 15
    }
    
    @MainActor
    func cellItem(fromFingerprint fingerprint: String) -> CellModel? {
        let parts = fingerprint.split(separator: "::")
        if parts[0] == CellModel.Role.board.rawValue {
            return board.cellByPosition(row: Int(parts[1])!, col: Int(parts[2])!)
        } else if parts[0] == CellModel.Role.rack.rawValue {
            return rack.cellByPosition(pos: Int(parts[1])!)
        } else {
            return nil
        }
    }
}

struct CellDropDelegate: DropDelegate {
    let drop: CellModel // Target cell.
    let viewModel: CellView
    
    func performDrop(info: DropInfo) -> Bool {
        
        let provider = info.itemProviders(for: [.text]).first
        
        provider?.loadObject(ofClass: NSString.self) { fingerprint, _ in
            DispatchQueue.main.async {
                guard
                    // Get drag source cell from DropInfo.
                    let fingerprint = fingerprint,
                    let drag = viewModel.cellItem(fromFingerprint: String(fingerprint as! Substring))
                else { return }
                
                // Special case: asterisk exchange - we check for extra conditions.
                if drop.isImmutable && drop.letterTile != nil && drop.letterTile!.isAsterisk && drop.letterTile!.char != drag.letterTile!.char {
                    // Trying to exchange asterisk for a wrong letter - no action.
                    return
                }
                
                viewModel.moveCell(drag: drag, drop: drop)
            }
        }
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

//#Preview {
//    CellView(cell: CellModel(row: 0, col: 0, pos: -1, letterTile: nil), boardIsLocked: false, boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru))
//}
