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
    
    @StateObject private var rackViewModel = RackViewModel.shared
    
    let gameId: String
    
    var body: some View {
        ZStack {
            if let game = viewModel.game {
                if isLandscape {
                    VStack {
                        List {
                            ForEach(Array(game.users.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Image(systemName: game.turn == index ? "person.fill" : "person")
                                    Text(item.name!)
                                    Spacer()
                                    Text("\(game.scores[index])")
                                }
                            }
                        }
                        
                        if hasTurn {
                            if isInChangeLetterMode {
                                ActionButton(label: "CHANGE LETTERS", action: {
                                    do {
                                        try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                                    } catch {
                                        print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: false)
                                ActionButton(label: "CANCEL", action: {
                                    viewModel.setChangeLettersMode(mode: false)
                                }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemBlue), maxWidth: false)
                            } else {
                                ActionButton(label: "CHANGE LETTERS", action: {
                                    viewModel.setChangeLettersMode(mode: true)
                                }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemBlue), maxWidth: false)
                                ActionButton(label: "SUBMIT", action: {
                                    do {
                                        try await viewModel.submitMove(gameId: game.id)
                                    } catch {
                                        print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemBlue), maxWidth: false)
                            }
                        }
                        
                        ActionButton(label: "STOP GAME", action: {
                            do {
                                try await viewModel.stopGame(gameId: game.id)
                            } catch {
                                print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                            }
                        }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: false)
                    }
                    .padding()
                } else {
                    HStack {
                        List {
                            ForEach(Array(game.users.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Image(systemName: game.turn == index ? "person.fill" : "person")
                                    Text(item.name!)
                                    Spacer()
                                    Text("\(game.scores[index])")
                                }
                            }
                        }
                        
                        if hasTurn {
                            VStack {
                                if isInChangeLetterMode {
                                    ActionButton(label: "CHANGE LETTERS", action: {
                                        do {
                                            try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                                        } catch {
                                            print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: false)
                                    ActionButton(label: "CANCEL", action: {
                                        viewModel.setChangeLettersMode(mode: false)
                                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemBlue), maxWidth: false)
                                } else {
                                    ActionButton(label: "CHANGE LETTERS", action: {
                                        viewModel.setChangeLettersMode(mode: true)
                                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemBlue), maxWidth: false)
                                    ActionButton(label: "SUBMIT", action: {
                                        do {
                                            try await viewModel.submitMove(gameId: game.id)
                                        } catch {
                                            print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemBlue), maxWidth: false)
                                }
                            }
                            
                            ActionButton(label: "STOP GAME", action: {
                                do {
                                    try await viewModel.stopGame(gameId: game.id)
                                } catch {
                                    print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                }
                            }, buttonSystemImage: "square.and.arrow.up", backGroundColor: Color(.systemOrange), maxWidth: false)
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.loadGame(gameId: gameId)
            viewModel.addListenerForGame()
        }
    }
    
    var isLandscape: Bool {
        return mainWindowSize.width > mainWindowSize.height
    }
    
    var isInChangeLetterMode: Bool {
        return rackViewModel.changeLettersMode
    }
    
    var hasTurn: Bool {
        guard let game = viewModel.game, let user = viewModel.currentUser else { return false }
        
        let userIndex = game.users.firstIndex { $0.userId == user.userId }
        
        return game.turn == userIndex
    }
}

#Preview {
    CommandView(gameId: "fake_id")
}
