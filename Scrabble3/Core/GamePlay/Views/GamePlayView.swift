//
//  GamePlayView.swift
//  Scrabble3
//
//  Created by Alex on 22/10/23.
//

import SwiftUI

struct GamePlayView: View {
    
    let gameId: String?
    
    var game: GameModel? = nil
    
    @StateObject private var viewModel = GamePlayViewModel.shared
    
    var body: some View {
        if let gameId = gameId {
            GeometryReader { proxy in
                if (isLandscape(proxy.size)) {
                    HStack {
                        BoardView()
                            .environment(\.mainWindowSize, proxy.size)
                        RackView()
                            .environment(\.mainWindowSize, proxy.size)
                        CommandView(gameId: gameId)
                            .environment(\.mainWindowSize, proxy.size)
                    }
                } else {
                    VStack {
                        BoardView()
                            .environment(\.mainWindowSize, proxy.size)
                        RackView()
                            .environment(\.mainWindowSize, proxy.size)
                        CommandView(gameId: gameId)
                            .environment(\.mainWindowSize, proxy.size)
                    }
                }
            }
            .task {
                viewModel.addListenerForMoves(gameId: gameId)
            }
            .onDisappear() {
                viewModel.removeListenerForMoves()
            }
        }
    }
    
    func isLandscape(_ size: CGSize) -> Bool {
        return size.width > size.height
    }
}

#Preview {
    GamePlayView(gameId: nil)
}
