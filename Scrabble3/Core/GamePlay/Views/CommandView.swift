//
//  CommandView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct CommandView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @StateObject private var viewModel: CommandViewModel
    
    @StateObject private var rackViewModel: RackViewModel
    
    let gameId: String
    
    init(gameId: String, boardViewModel: BoardViewModel, rackViewModel: RackViewModel, gameViewModel: GamePlayViewModel) {
        self.gameId = gameId
        
        _rackViewModel = StateObject(wrappedValue: rackViewModel)
        
        let viewModel = CommandViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel, gameViewModel: gameViewModel)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            if let game = viewModel.game {
                if isLandscape {
                    VStack {
                        List {
                            ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Image(systemName: game.turn == index ? "person.fill" : "person")
                                    Text(item.user.initials)
                                    Spacer()
                                    Text("\(item.score)")
                                }
                            }
                        }
                        
                        if hasTurn {
                            if isInChangeLetterMode {
                                ActionButton(label: "ПОМЕНЯТЬ", action: {
                                    do {
                                        try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                                    } catch {
                                        print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                
                                ActionButton(label: "ОТМЕНИТЬ", action: {
                                    viewModel.setChangeLettersMode(mode: false)
                                }, buttonSystemImage: "arrow.circlepath", backGroundColor: Color(.systemBlue), maxWidth: false)
                            } else {
                                ActionButton(label: "ПОМЕНЯТЬ БУКВЫ", action: {
                                    viewModel.setChangeLettersMode(mode: true)
                                }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                
                                ActionButton(label: "ГОТОВО", action: {
                                    do {
                                        try await viewModel.submitMove(gameId: game.id)
                                    } catch {
                                        print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "checkmark", backGroundColor: Color(.systemBlue), maxWidth: false)
                                
                                ActionButton(label: "ПРОВЕРКА", action: {
                                    await viewModel.validateMove(gameId: game.id)
                                }, buttonSystemImage: "questionmark.circle.fill", backGroundColor: Color(.systemGray), maxWidth: false)
                            }
                        }
                        
                        if !isInChangeLetterMode {
                            ActionButton(label: "ОТЛОЖИТЬ ИГРУ", action: {
                                do {
                                    try await viewModel.suspendGame(gameId: game.id, abort: false)
                                } catch {
                                    print("DEBUG :: Error suspending game: \(error.localizedDescription)")
                                }
                            }, buttonSystemImage: "stop.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                            
                            ActionButton(label: "ВЫЙТИ ИЗ ИГРЫ", action: {
                                do {
                                    try await viewModel.suspendGame(gameId: game.id, abort: true)
                                } catch {
                                    print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                }
                            }, buttonSystemImage: "xmark.bin", backGroundColor: Color(.systemRed), maxWidth: false)
                        }
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        List {
                            ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                                HStack(spacing: 12) {
                                    Image(systemName: game.turn == index ? "person.fill" : "person")
                                    Text(item.user.initials)
                                    Spacer()
                                    Text("\(item.score)")
                                }
                            }
                        }
                        
                        VStack {
                            if hasTurn {
                                if isInChangeLetterMode {
                                    ActionButton(label: "ПОМЕНЯТЬ", action: {
                                        do {
                                            try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                                        } catch {
                                            print("DEBUG :: Error changing letters: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                    
                                    ActionButton(label: "ОТМЕНИТЬ", action: {
                                        viewModel.setChangeLettersMode(mode: false)
                                    }, buttonSystemImage: "arrow.circlepath", backGroundColor: Color(.systemBlue), maxWidth: false)
                                } else {
                                    ActionButton(label: "ПОМЕНЯТЬ БУКВЫ", action: {
                                        viewModel.setChangeLettersMode(mode: true)
                                    }, buttonSystemImage: "arrow.2.circlepath.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                    
                                    ActionButton(label: "ГОТОВО", action: {
                                        do {
                                            try await viewModel.submitMove(gameId: game.id)
                                        } catch {
                                            print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                        }
                                    }, buttonSystemImage: "checkmark", backGroundColor: Color(.systemBlue), maxWidth: false)
                                    
                                    ActionButton(label: "ПРОВЕРКА", action: {
                                        await viewModel.validateMove(gameId: game.id)
                                    }, buttonSystemImage: "questionmark.circle.fill", backGroundColor: Color(.systemGray), maxWidth: false)
                                }
                            }
                            
                            if !isInChangeLetterMode {
                                ActionButton(label: "ОТЛОЖИТЬ ИГРУ", action: {
                                    do {
                                        try await viewModel.suspendGame(gameId: game.id, abort: false)
                                    } catch {
                                        print("DEBUG :: Error suspending game: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "stop.circle", backGroundColor: Color(.systemOrange), maxWidth: false)
                                
                                ActionButton(label: "ВЫЙТИ ИЗ ИГРЫ", action: {
                                    do {
                                        try await viewModel.suspendGame(gameId: game.id, abort: true)
                                    } catch {
                                        print("DEBUG :: Error leaving game: \(error.localizedDescription)")
                                    }
                                }, buttonSystemImage: "xmark.bin", backGroundColor: Color(.systemRed), maxWidth: false)
                            }
                        }
                    }
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
        
        let userIndex = game.players.firstIndex { $0.user.userId == user.userId }
        
        return game.turn == userIndex
    }
}

//#Preview {
//    let boardViewModel = BoardViewModel()
//    let rackViewModel = RackViewModel()
//    CommandView(gameId: "fake_id", boardViewModel: boardViewModel, rackViewModel: rackViewModel, gameViewModel: GamePlayViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel))
//}

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        let boardViewModel = BoardViewModel()
        let rackViewModel = RackViewModel()
        CommandView(gameId: "fake_id", boardViewModel: boardViewModel, rackViewModel: rackViewModel, gameViewModel: GamePlayViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel))
    }
}
