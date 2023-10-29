//
//  CommandView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct CommandView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @StateObject private var viewModel = CommandViewModel()
    
    let gameId: String?
    
    @State var playerList = [Player]()
    
    var body: some View {
        if let gameId = gameId {
            if isLandscape {
                VStack {
                    List {
                        ForEach(playerList, id: \.id.self)  { item in
                            HStack {
                                Text(item.name)
                                Text("\(item.score)")
                                if item.hasTurn {
                                    Text("Current")
                                }
                            }
                        }
                    }.task {
                        playerList = await viewModel.getPlayersList(gameId: gameId)
                    }
                    
                    ActionButton(label: "STOP GAME", action: {
                        do {
                            try await viewModel.stopGame(gameId: gameId)
                        } catch {
                            print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                        }
                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: false)
                }
                .padding()
            } else {
                HStack {
                    List {
                        ForEach(playerList, id: \.id.self)  { item in
                            HStack {
                                Text(item.name)
                                Text("\(item.score)")
                                if item.hasTurn {
                                    Text("Current")
                                }
                            }
                        }
                    }.task {
                        playerList = await viewModel.getPlayersList(gameId: gameId)
                    }
                    ActionButton(label: "STOP GAME", action: {
                        do {
                            try await viewModel.stopGame(gameId: gameId)
                        } catch {
                            print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                        }
                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: false)
                }
                .padding()
            }
        }
    }
    
    var isLandscape: Bool {
        return mainWindowSize.width > mainWindowSize.height
    }
}

#Preview {
    CommandView(gameId: nil)
}
