//
//  GamePlayView.swift
//  Scrabble3
//
//  Created by Alex on 22/10/23.
//

import SwiftUI

struct GamePlayView: View {
    
    let gameId: String?
    
    var body: some View {
        GeometryReader { proxy in
            if (proxy.size.width > proxy.size.height) {
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
    }
}

#Preview {
    GamePlayView(gameId: nil)
}
