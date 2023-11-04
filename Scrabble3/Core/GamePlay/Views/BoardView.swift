//
//  BoardView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct BoardView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @StateObject private var boardViewModel = BoardViewModel.shared
    @StateObject private var rackViewModel = RackViewModel.shared
    
    let boardIsLocked: Bool
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0...boardViewModel.rows - 1, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0...boardViewModel.cols - 1, id: \.self) { col in
                        let cell = boardViewModel.cellByPosition(row: row, col: col)
                        CellView(cell: cell, boardIsLocked: boardIsLocked)
                            .frame(width: idealCellSize, height: idealCellSize)
                    }
                }
            }
        }
        .padding()
        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
        .fullScreenCover(isPresented: $boardViewModel.asteriskDialogPresented) {
            AsteriskDialogView(asteriskDialogPresented: $boardViewModel.asteriskDialogPresented, asteriskRow: boardViewModel.asteriskRow!, asteriskCol: boardViewModel.asteriskCol!)
        }
        .sheet(isPresented: $boardViewModel.moveInfoDialogPresented) {
            MoveInfoDialogView(words: boardViewModel.moveWordsSummary, score: boardViewModel.moveTotalScore, bonus: boardViewModel.getMoveBonus, isPresented: $boardViewModel.moveInfoDialogPresented)
        }
    }
    
    var idealCellSize: CGFloat {
        return (min(mainWindowSize.width, mainWindowSize.height) - 40) / 15
    }
}

#Preview {
    BoardView(boardIsLocked: false)
}
