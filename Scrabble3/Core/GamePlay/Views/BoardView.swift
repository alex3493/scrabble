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
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(0...boardViewModel.rows - 1, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0...boardViewModel.cols - 1, id: \.self) { col in
                        let cell = boardViewModel.cellByPosition(row: row, col: col)
                        CellView(cell: cell)
                            .frame(width: idealCellSize, height: idealCellSize)
                    }
                }
            }
        }
        .padding()
        .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
    }
    
    var idealCellSize: CGFloat {
        return (min(mainWindowSize.width, mainWindowSize.height) - 40) / 15
    }
}

#Preview {
    BoardView()
}
