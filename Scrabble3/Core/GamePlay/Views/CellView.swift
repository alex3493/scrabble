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
    
    @State var isWordsInfoPresented = false
    
    @State var moveWordsSummary: [(String, WordInfo?, Int)] = []
    
    @StateObject private var commandViewModel: CommandViewModel
    
    @StateObject private var board: BoardViewModel
    @StateObject private var rack: RackViewModel
    
    @GestureState private var dragState = DragState.inactive
    
    init(cell: CellModel, commandViewModel: CommandViewModel) {
        self.cell = cell
        
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _board = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rack = StateObject(wrappedValue: commandViewModel.rackViewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cellPiece = ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(cell.isEmpty && cell.isCenterCell ? Color.gray : cellFill)
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
                    .font(.system(size: idealCellSize / 2))
                    .colorInvert()
                } else {
                    Text(!cell.isEmpty
                         ? cell.letterTile!.char
                         : " "
                    )
                    .font(.system(size: idealCellSize / 2))
                    .colorInvert()
                }
            }
            
            if cell.isImmutable && cell.role == .board && !cell.isEmpty {
                // Existing word - show definitions.
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
            } else {
                cellPiece
            }
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

#Preview {
    CellView(cell: CellModel(row: 0, col: 0, pos: -1, letterTile: nil), commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}
