//
//  RackView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct RackView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @StateObject private var boardViewModel: BoardViewModel
    @StateObject private var rackViewModel: RackViewModel
    @StateObject private var commandViewModel: CommandViewModel
    
    @GestureState private var dragState = DragState.inactive
    
    @StateObject private var moveCellHelper: MoveCellHelper
    
    init(commandViewModel: CommandViewModel) {
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _boardViewModel = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rackViewModel = StateObject(wrappedValue: commandViewModel.rackViewModel)
        
        _moveCellHelper = StateObject(wrappedValue: MoveCellHelper(rackViewModel: commandViewModel.rackViewModel, boardViewModel: commandViewModel.boardViewModel, commandViewModel: commandViewModel))
    }
    
    var body: some View {
        GeometryReader { proxy in
            if rackViewModel.cells.count > 0 {
                if (isLandscape(size: proxy.size)) {
                    HStack() {
                        ForEach(0..<Constants.Game.Rack.size, id: \.self) { pos in
                            let cell = rackViewModel.cellByPosition(pos: pos)
                            
                            let cellView = CellView(cell: cell, commandViewModel: commandViewModel)
                                .frame(width: idealCellSize, height: idealCellSize)
                                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                                .zIndex(dragState.isDraggingCell(cell: cell) ? 1 : 0)
                                .offset(x: dragState.cellTranslation(cell: cell).width, y: dragState.cellTranslation(cell: cell).height)
                            
                            if !cell.isEmpty {
                                cellView
                                    .gesture(
                                        DragGesture(minimumDistance: 0.01, coordinateSpace: .global)
                                            .updating(self.$dragState, body: { (currentState, gestureState, transaction) in
                                                gestureState = .dragging(translation: currentState.translation, selectedItem: cell)
                                            })
                                            .onEnded { gesture in
                                                print("Drag stopped!", gesture.location)
                                                
                                                moveCellHelper.onPerformDrop(value: gesture.location, cell: cell)
                                            }
                                    )
                                
                                
                            } else {
                                cellView
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 4) {
                        ForEach(0..<Constants.Game.Rack.size, id: \.self) { pos in
                            let cell = rackViewModel.cellByPosition(pos: pos)
                            
                            let cellView = CellView(cell: cell, commandViewModel: commandViewModel)
                                .frame(width: idealCellSize, height: idealCellSize)
                                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                                .zIndex(dragState.isDraggingCell(cell: cell) ? 1 : 0)
                                .offset(x: dragState.cellTranslation(cell: cell).width, y: dragState.cellTranslation(cell: cell).height)
                            
                            if !cell.isEmpty {
                                cellView
                                    .gesture(
                                        DragGesture(minimumDistance: 0.01, coordinateSpace: .global)
                                            .updating(self.$dragState, body: { (currentState, gestureState, transaction) in
                                                gestureState = .dragging(translation: currentState.translation, selectedItem: cell)
                                            })
                                            .onEnded { gesture in
                                                print("Drag stopped!", gesture.location)
                                                
                                                moveCellHelper.onPerformDrop(value: gesture.location, cell: cell)
                                            }
                                    )
                                
                                
                            } else {
                                cellView
                            }
                        }
                    }
                    .padding()
                }
                
                
            }
        }
        .zIndex(dragState.isDragging ? -1 : 0)
    }
    
    func isLandscape(size: CGSize) -> Bool {
        return size.width > size.height
    }
    
    func idealCellSize(size: CGSize) -> CGFloat {
        return (min(size.width, size.height) - 80) / CGFloat(Constants.Game.Rack.size)
    }
    
    //    var isLandscape: Bool {
    //        return mainWindowSize.width > mainWindowSize.height
    //    }
    
    var idealCellSize: CGFloat {
        return (min(mainWindowSize.width, mainWindowSize.height) - 40) / 15
    }
    
    var isLettersChangeMode: Bool {
        return rackViewModel.changeLettersMode
    }
    
}

#Preview {
    RackView(commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}

