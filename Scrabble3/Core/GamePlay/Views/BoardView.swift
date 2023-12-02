//
//  BoardView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct BoardView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @StateObject private var boardViewModel: BoardViewModel
    @StateObject private var rackViewModel: RackViewModel
    @StateObject private var commandViewModel: CommandViewModel
    
    let boardIsLocked: Bool
    
    init(boardIsLocked: Bool, commandViewModel: CommandViewModel) {
        self.boardIsLocked = boardIsLocked
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _boardViewModel = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rackViewModel = StateObject(wrappedValue: commandViewModel.rackViewModel)
    }
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0...LetterStoreBase.rows - 1, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0...LetterStoreBase.cols - 1, id: \.self) { col in
                        let cell = boardViewModel.cellByPosition(row: row, col: col)
                        CellView(cell: cell, boardIsLocked: boardIsLocked, commandViewModel: commandViewModel)
                            .frame(width: idealCellSize, height: idealCellSize)
                    }
                }
            }
        }
        .padding()
        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
        .fullScreenCover(isPresented: $boardViewModel.asteriskDialogPresented) {
            AsteriskDialogView(asteriskDialogPresented: $boardViewModel.asteriskDialogPresented, asteriskRow: boardViewModel.asteriskRow!, asteriskCol: boardViewModel.asteriskCol!, commandViewModel: commandViewModel)
        }
        .fullScreenCover(isPresented: $boardViewModel.moveInfoDialogPresented) {
            MoveInfoDialogView(words: boardViewModel.moveWordsSummary, score: boardViewModel.moveTotalScore, bonus: boardViewModel.getMoveBonus, commandViewModel: commandViewModel, isPresented: $boardViewModel.moveInfoDialogPresented)
        }
    }
    
    var idealCellSize: CGFloat {
        return (min(mainWindowSize.width, mainWindowSize.height) - 40) / 15
    }
}

#Preview {
    BoardView(boardIsLocked: false, commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}
