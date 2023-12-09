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
    
    init(commandViewModel: CommandViewModel) {
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _boardViewModel = StateObject(wrappedValue: commandViewModel.boardViewModel)
        _rackViewModel = StateObject(wrappedValue: commandViewModel.rackViewModel)
    }
    
    var body: some View {
        GeometryReader { proxy in
            if rackViewModel.cells.count > 0 {
                if (isLandscape(size: proxy.size)) {
                    HStack() {
                        Group {
                            ForEach(0..<Constants.Game.Rack.size, id: \.self) { pos in
                                let cell = rackViewModel.cellByPosition(pos: pos)
                                CellView(cell: cell, boardIsLocked: false, commandViewModel: commandViewModel)
                                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                            }
                        }
                    }
                    .padding()
                } else {
                    VStack(spacing: 4) {
                        Group {
                            ForEach(0..<Constants.Game.Rack.size, id: \.self) { pos in
                                let cell = rackViewModel.cellByPosition(pos: pos)
                                CellView(cell: cell, boardIsLocked: false, commandViewModel: commandViewModel)
                                    .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 40)
                }
                
                // Text("Rack: \(proxy.size.width) x \(proxy.size.height)")
            }
        }
    }
    
    func isLandscape(size: CGSize) -> Bool {
        return size.width > size.height
    }
    
//    func idealCellSize(size: CGSize) -> CGFloat {
//        return (min(size.width, size.height) - 80) / CGFloat(Constants.Game.Rack.size)
//    }
    
//    var isLandscape: Bool {
//        return mainWindowSize.width > mainWindowSize.height
//    }
    
//    var idealCellSize: CGFloat {
//        return (min(mainWindowSize.width, mainWindowSize.height) - 40) / 15
//    }
    
    var isLettersChangeMode: Bool {
        return rackViewModel.changeLettersMode
    }
}

#Preview {
    RackView(commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}

