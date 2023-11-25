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
    
    init(boardViewModel: BoardViewModel, rackViewModel: RackViewModel) {
        _boardViewModel = StateObject(wrappedValue: boardViewModel)
        _rackViewModel = StateObject(wrappedValue: rackViewModel)
    }
    
    var body: some View {
        if rackViewModel.cells.count > 0 {
            if (isLandscape) {
                VStack() {
                    Group {
                        ForEach(0..<LetterStoreBase.size, id: \.self) { pos in
                            let cell = rackViewModel.cellByPosition(pos: pos)
                            CellView(cell: cell, boardIsLocked: false, boardViewModel: boardViewModel, rackViewModel: rackViewModel)
                                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                                .frame(width: idealCellSize)
                        }
                    }
                }
                .padding()
            } else {
                HStack() {
                    Group {
                        ForEach(0..<LetterStoreBase.size, id: \.self) { pos in
                            let cell = rackViewModel.cellByPosition(pos: pos)
                            CellView(cell: cell, boardIsLocked: false, boardViewModel: boardViewModel, rackViewModel: rackViewModel)
                                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                                .frame(width: idealCellSize)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    var isLandscape: Bool {
        return mainWindowSize.width > mainWindowSize.height
    }
    
    var idealCellSize: CGFloat {
        return min(mainWindowSize.width, mainWindowSize.height) / 15
    }
    
    var isLettersChangeMode: Bool {
        return rackViewModel.changeLettersMode
    }
}

#Preview {
    RackView(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru))
}

