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
    }
    
    func isLandscape(_ size: CGSize) -> Bool {
        return size.width > size.height
    }
}

#Preview {
    GamePlayView(gameId: nil)
}
