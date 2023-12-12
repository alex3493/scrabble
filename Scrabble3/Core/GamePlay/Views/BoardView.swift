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
    
    @GestureState private var dragState = DragState.inactive
    
    @StateObject private var moveCellHelper: MoveCellHelper
    
    let boardIsLocked: Bool
    
    init(boardIsLocked: Bool, commandViewModel: CommandViewModel) {
        self.boardIsLocked = boardIsLocked
        
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _boardViewModel = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rackViewModel = StateObject(wrappedValue: commandViewModel.rackViewModel)
        
        _moveCellHelper = StateObject(wrappedValue: MoveCellHelper(rackViewModel: commandViewModel.rackViewModel, boardViewModel: commandViewModel.boardViewModel, commandViewModel: commandViewModel))
    }
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<Constants.Game.Board.rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<Constants.Game.Board.cols, id: \.self) { col in
                        let cell = boardViewModel.cellByPosition(row: row, col: col)
                        
                        let cellView = CellView(cell: cell, commandViewModel: commandViewModel)
                            .frame(width: idealCellSize, height: idealCellSize)
                            .zIndex(dragState.isDraggingCell(cell: cell) ? 1 : 0)
                        
                        if !cell.isEmpty && !cell.isImmutable {
                            cellView
                                .offset(x: dragState.cellTranslation(cell: cell).width, y: dragState.cellTranslation(cell: cell).height)
                                .gesture(
                                    DragGesture(minimumDistance: 0.01, coordinateSpace: .global)
                                        .updating(self.$dragState, body: { (currentState, gestureState, transaction) in
                                            gestureState = .dragging(translation: currentState.translation, selectedItem: cell)
                                        })
                                        .onEnded { gesture in
                                            print("Drag stopped!", gesture.location)
                                            
                                            moveCellHelper.onPerformDrop(value: gesture.location, cell: cell, boardIsLocked: boardIsLocked)
                                        }
                                )
                        } else {
                            cellView
                        }
                    }
                }
                .zIndex(dragState.isDraggingFromRow(row: row) ? 1 : 0)
            }
        }
        .zIndex(dragState.isDragging ? 1 : -1)
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
