//
//  CommandView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct CommandView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @StateObject private var viewModel: CommandViewModel
    
    @StateObject private var rackViewModel: RackViewModel
    
    let errorStore = ErrorStore.shared
    
    let gameId: String
    
    init(gameId: String, commandViewModel: CommandViewModel) {
        self.gameId = gameId
        
        _rackViewModel = StateObject(wrappedValue: commandViewModel.rackViewModel)
        _viewModel = StateObject(wrappedValue: commandViewModel)
    }
    
    func hasTurnButtons(game: GameModel, isInChangeLetterMode: Bool) -> some View {
        Group {
            if isInChangeLetterMode {
                ActionImageButton(label: "", action: {
                    do {
                        try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                    } catch {
                        print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                        errorStore.showGamePlayAlertView(withMessage: error.localizedDescription)
                    }
                }, buttonSystemImage: "arrow.2.circlepath", backGroundColor: Color(.systemPink), maxWidth: false, disabled: !rackViewModel.hasLettersMarkedForChange)
                
                ActionImageButton(label: "", action: {
                    viewModel.setChangeLettersMode(mode: false)
                }, buttonSystemImage: "arrowshape.turn.up.backward.fill", backGroundColor: Color(.systemGray), maxWidth: false)
            } else {
                ActionImageButton(label: "", action: {
                    viewModel.setChangeLettersMode(mode: true)
                }, buttonSystemImage: "arrow.2.circlepath", backGroundColor: Color(.systemOrange), maxWidth: false)
                
                ActionImageButton(label: "", action: {
                    await viewModel.validateMove(gameId: game.id)
                }, buttonSystemImage: "checkmark", backGroundColor: Color(.systemGreen), maxWidth: false)
            }
        }
    }
    func exitGameButtons(game: GameModel) -> some View {
        Group {
            ActionImageButton(label: "", action: {
                do {
                    try await viewModel.suspendGame(gameId: game.id, abort: false)
                } catch {
                    print("DEBUG :: Error suspending game: \(error.localizedDescription)")
                    errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                }
            }, buttonSystemImage: "figure.walk.motion", backGroundColor: Color(.systemRed), maxWidth: false)
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            if let game = viewModel.game {
                HStack(alignment: .top) {
                    if !isInChangeLetterMode {
                        Spacer()
                        
                        exitGameButtons(game: game)
                    }
                    
                    if hasTurn {
                        Spacer()
                        
                        hasTurnButtons(game: game, isInChangeLetterMode: isInChangeLetterMode)
                    }
                }
                .padding()
                // Text("Command: \(proxy.size.width) x \(proxy.size.height)")
            }
        }
        .onAppear() {
            viewModel.currentUser = authViewModel.currentUser
        }
        .task {
            await viewModel.loadGame(gameId: gameId)
            viewModel.addListenerForGame()
        }
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

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        let boardViewModel = BoardViewModel(lang: .ru)
        let rackViewModel = RackViewModel(lang: .ru)
        CommandView(gameId: "fake_id", commandViewModel: CommandViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel))
    }
}
