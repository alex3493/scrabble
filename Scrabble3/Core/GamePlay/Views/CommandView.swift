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
                                    Text(item.initials)
                                    Spacer()
                                    Text("\(game.scores[index])")
                                }
                            }
                        }
                        
                        if hasTurn {
                            if isInChangeLetterMode {
                                ActionButton(label: "SUBMIT", action: {
                                    do {
                                        try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                                    } catch {
                                        print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                
                                ActionButton(label: "CANCEL", action: {
                                    viewModel.setChangeLettersMode(mode: false)
                                }, buttonSystemImage: "arrow.circlepath", backGroundColor: Color(.systemBlue), maxWidth: false)
                            } else {
                                ActionButton(label: "CHANGE LETTERS", action: {
                                    viewModel.setChangeLettersMode(mode: true)
                                }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                
                                ActionButton(label: "SUBMIT", action: {
                                    do {
                                        try await viewModel.submitMove(gameId: game.id)
                                    } catch {
                                        print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "checkmark", backGroundColor: Color(.systemBlue), maxWidth: false)
                                
                                ActionButton(label: "VALIDATE", action: {
                                    do {
                                        try await viewModel.validateMove(gameId: game.id)
                                    } catch {
                                        print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "questionmark.circle.fill", backGroundColor: Color(.systemGray), maxWidth: false)
                            }
                        }
                        
                        if !isInChangeLetterMode {
                            ActionButton(label: "SUSPEND GAME", action: {
                                do {
                                    try await viewModel.suspendGame(gameId: game.id, abort: false)
                                } catch {
                                    print("DEBUG :: Error suspending game: \(error.localizedDescription)")
                                }
                            }, buttonSystemImage: "stop.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                            
                            ActionButton(label: "LEAVE GAME", action: {
                                do {
                                    try await viewModel.suspendGame(gameId: game.id, abort: true)
                                } catch {
                                    print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                }
                            }, buttonSystemImage: "xmark.bin", backGroundColor: Color(.systemRed), maxWidth: false)
                        }
                    }
                    .padding()
                } else {
                    HStack {
                        List {
                            ForEach(Array(game.users.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Image(systemName: game.turn == index ? "person.fill" : "person")
                                    Text(item.initials)
                                    Spacer()
                                    Text("\(game.scores[index])")
                                }
                            }
                        }
                        
                        VStack {
                            if hasTurn {
                                if isInChangeLetterMode {
                                    ActionButton(label: "SUBMIT", action: {
                                        do {
                                            try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                                        } catch {
                                            print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                    
                                    ActionButton(label: "CANCEL", action: {
                                        viewModel.setChangeLettersMode(mode: false)
                                    }, buttonSystemImage: "arrow.circlepath", backGroundColor: Color(.systemBlue), maxWidth: false)
                                } else {
                                    ActionButton(label: "CHANGE LETTERS", action: {
                                        viewModel.setChangeLettersMode(mode: true)
                                    }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                    
                                    ActionButton(label: "SUBMIT", action: {
                                        do {
                                            try await viewModel.submitMove(gameId: game.id)
                                        } catch {
                                            print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "checkmark", backGroundColor: Color(.systemBlue), maxWidth: false)
                                    
                                    ActionButton(label: "VALIDATE", action: {
                                        do {
                                            try await viewModel.validateMove(gameId: game.id)
                                        } catch {
                                            print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "questionmark.circle.fill", backGroundColor: Color(.systemGray), maxWidth: false)
                                }
                            }
                            
                            if !isInChangeLetterMode {
                                ActionButton(label: "SUSPEND GAME", action: {
                                    do {
                                        try await viewModel.suspendGame(gameId: game.id, abort: false)
                                    } catch {
                                        print("DEBUG :: Error suspending game: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "stop.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                
                                ActionButton(label: "LEAVE GAME", action: {
                                    do {
                                        try await viewModel.suspendGame(gameId: game.id, abort: true)
                                    } catch {
                                        print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "xmark.bin", backGroundColor: Color(.systemRed), maxWidth: false)
                            }
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
