//
//  ControllerView.swift
//  Scrabble3
//
//  Created by Alex on 14/12/23.
//

import SwiftUI

struct ControllerView: View {
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    let gameId: String
    let boardIsLocked: Bool
    let commandViewModel: CommandViewModel
    
    var body: some View {
        GeometryReader { proxy in
            if (isLandscape(proxy.size)) {
                VStack(alignment: .trailing) {
                    PlayerListView(viewModel: commandViewModel)
                        .padding()
                    RackView(boardIsLocked: boardIsLocked, commandViewModel: commandViewModel)
                        .environment(\.mainWindowSize, proxy.size)
                    CommandView(gameId: gameId, commandViewModel: commandViewModel)
                        // TODO: make it better!
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .environment(\.mainWindowSize, proxy.size)
                }
            } else {
                RackView(boardIsLocked: boardIsLocked, commandViewModel: commandViewModel)
                    .environment(\.mainWindowSize, proxy.size)
                PlayerListView(viewModel: commandViewModel)
                    .padding()
                CommandView(gameId: gameId, commandViewModel: commandViewModel)
                    .environment(\.mainWindowSize, proxy.size)
            }
        }
    }
    
    func isLandscape(_ size: CGSize) -> Bool {
        return size.width > size.height
    }
}

#Preview {
    ControllerView(gameId: "fake_game_id", boardIsLocked: false, commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}
