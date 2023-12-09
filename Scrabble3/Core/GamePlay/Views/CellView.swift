//
//  CellView.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import SwiftUI

enum DragState {
    case inactive
    case pressing
    case dragging(translation: CGSize)
    
    var translation: CGSize {
        switch self {
        case .inactive, .pressing:
            return .zero
        case .dragging(let translation):
            return translation
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .dragging:
            return true
        case .pressing, .inactive:
            return false
        }
    }
    
    var isPressing: Bool {
        switch self {
        case .inactive:
            return false
        case .pressing, .dragging:
            return true
        }
    }
}

struct CellView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var cell: CellModel
    
    var boardIsLocked: Bool
    
    @State var isWordsInfoPresented = false
    
    @State var moveWordsSummary: [(String, WordInfo?, Int)] = []
    
    @StateObject private var commandViewModel: CommandViewModel
    
    @StateObject private var board: BoardViewModel
    @StateObject private var rack: RackViewModel
    
    @GestureState private var dragState = DragState.inactive
    
    init(cell: CellModel, boardIsLocked: Bool, commandViewModel: CommandViewModel) {
        self.cell = cell
        self.boardIsLocked = boardIsLocked
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _board = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rack = StateObject(wrappedValue: commandViewModel.rackViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cellPiece = ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(cell.isEmpty && cell.isCenterCell ? .gray : cellFill)
                    .onAppear() {
                        let frame = geometry.frame(in: .global)
                        
                        if cell.role == .board {
                            let index = cell.row * Constants.Game.Board.cols + cell.col
                            self.board.cellFrames[index] = frame
                        } else {
                            self.rack.cellFrames[cell.pos] = frame
                        }
                    }
                
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
                if cell.cellStatus == .empty {
                    // Empty tile.
                    cellPiece
                } else if !cell.isImmutable && !isCellReadyForLetterChange {
                    // Current move board or rack tiles - free move on board, in rack and between board and rack.
                    cellPiece
                        .offset(x: self.dragState.translation.width, y: self.dragState.translation.height)
                        .gesture(LongPressGesture(minimumDuration: 0.01)
                            .sequenced(before: DragGesture(coordinateSpace: .global)
                                .onEnded { gesture in
                                    onDrop(value: gesture.location, cell: cell)
                                    
                                })
                                .updating(self.$dragState, body: { (currentState, gestureState, transaction) in
                                    switch currentState {
                                    case .first:
                                        print("Drag started!")
                                        gestureState = .pressing
                                    case .second(true, let drag):
                                        gestureState = .dragging(translation: drag?.translation ?? .zero)
                                    default:
                                        break
                                    }
                                })
                        )
                } else if cell.isImmutable && cell.role == .board && cell.letterTile != nil && cell.letterTile!.isAsterisk {
                    // Exchange asterisk on board (rack --> board move).
                    cellPiece
                        .onTapGesture {
                            showWordDefinitions(row: cell.row, col: cell.col)
                        }
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
                } else if cell.isImmutable && cell.role == .board && !cell.isEmpty {
                    cellPiece
                        .onTapGesture {
                            showWordDefinitions(row: cell.row, col: cell.col)
                        }
                } else {
                    cellPiece
                }
            } else if !cell.isEmpty {
                cellPiece
                    .onTapGesture {
                        showWordDefinitions(row: cell.row, col: cell.col)
                    }
            } else {
                cellPiece
            }
        }
    }
    
    func onDrop(value: CGPoint, cell drag: CellModel) {
        print("On drop", value, cell.pos, cell.row, cell.col)
        
        if !boardIsLocked {
            
            let rackDropCellIndex = rack.cellIndexFromPoint(value.x, value.y)
            let boardDropCellIndex = board.cellIndexFromPoint(value.x, value.y)
            
            print("Cell indices: rack / board", rackDropCellIndex ?? "N/A", boardDropCellIndex ?? "N/A")
            
            var drop: CellModel? = nil
            
            if let rackDropCellIndex = rackDropCellIndex {
                drop = rack.cells[rackDropCellIndex]
            }
            
            if let boardDropCellIndex = boardDropCellIndex {
                drop = board.cells[boardDropCellIndex]
            }
            
            guard let drop = drop else { return }
            
            if drop.isImmutable && drop.letterTile != nil && drop.letterTile!.isAsterisk && drop.letterTile!.char != drag.letterTile!.char {
                // Trying to exchange asterisk for a wrong letter - no action.
                return
            }
            
            if drop.cellStatus == .empty || (!drop.isImmutable && !isCellReadyForLetterChange) {
                moveCell(drag: drag, drop: drop)
                
                // Debounce automatic validation.
                let debounce = Debounce(duration: 1)
                debounce.submit {
                    Task {
                        do {
                            try await commandViewModel.validateMove()
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
    
    @MainActor
    private func showWordDefinitions(row: Int, col: Int) {
        print("showWordDefinitions cell and count", row, col, commandViewModel.gameMoves.count)
        
        // TODO::20 - this is not working in some cases!
        let allWords = commandViewModel.gameMoves.flatMap { $0.words }
        
        let wordsAtCell = allWords.filter { $0.isCellInWord(row: row, col: col) }
        
        var summary = [(String, WordInfo?, Int)]()
        
        wordsAtCell.forEach { word in
            summary.append((word.word, word.wordDefinition, word.score))
        }
        
        print("summary", summary)
        
        board.moveWordsSummary = summary
        board.moveTotalScore = nil
        board.moveInfoDialogPresented = true
    }
}

//struct CellDropDelegate: DropDelegate {
//    let drop: CellModel // Target cell.
//    let viewModel: CellView
//    
//    // Interact with game controller.
//    let commandViewModel: CommandViewModel
//    
//    func performDrop(info: DropInfo) -> Bool {
//        
//        let provider = info.itemProviders(for: [.text]).first
//        
//        provider?.loadObject(ofClass: NSString.self) { fingerprint, _ in
//            DispatchQueue.main.async {
//                guard
//                    // Get drag source cell from DropInfo.
//                    let fingerprint = fingerprint,
//                    let drag = viewModel.cellItem(fromFingerprint: String(fingerprint as! Substring))
//                else { return }
//                
//                // Special case: asterisk exchange - we check for extra conditions.
//                if drop.isImmutable && drop.letterTile != nil && drop.letterTile!.isAsterisk && drop.letterTile!.char != drag.letterTile!.char {
//                    // Trying to exchange asterisk for a wrong letter - no action.
//                    return
//                }
//                
//                viewModel.moveCell(drag: drag, drop: drop)
//                
//                // Debounce automatic validation.
//                let debounce = Debounce(duration: 1)
//                debounce.submit {
//                    Task {
//                        do {
//                            try await commandViewModel.validateMove()
//                        } catch {
//                            // We swallow exception here, later we may change it...
//                            // TODO: this is not OK. We should consume this exception in model in order to update view...
//                            print("On-the-fly validation failed", error.localizedDescription)
//                        }
//                    }
//                }
//            }
//        }
//        
//        return true
//    }
//    
//    func dropUpdated(info: DropInfo) -> DropProposal? {
//        return DropProposal(operation: .move)
//    }
//}

#Preview {
    CellView(cell: CellModel(row: 0, col: 0, pos: -1, letterTile: nil), boardIsLocked: false, commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}
