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
    
    let gameId: String
    
    init(gameId: String, commandViewModel: CommandViewModel) {
        self.gameId = gameId
        
        _rackViewModel = StateObject(wrappedValue: commandViewModel.rackViewModel)
        _viewModel = StateObject(wrappedValue: commandViewModel)
    }
    
    func playerList(game: GameModel) -> some View {
        List {
            ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    Image(systemName: game.turn == index ? "person.fill" : "person")
                    Text(item.user.name != nil && item.user.name!.count > 5 ? item.user.initials : item.user.name ?? "")
                    Spacer()
                    Text("\(item.score)")
                }
            }
        }
        .listStyle(.plain)
    }
    
    func hasTurnButtons(game: GameModel, isInChangeLetterMode: Bool) -> some View {
        Group {
            if isInChangeLetterMode {
                ActionImageButton(label: "", action: {
                    do {
                        try await viewModel.changeLetters(gameId: game.id, confirmed: true)
                    } catch {
                        print("DEBUG :: Error changing letter: \(error.localizedDescription)")
                    }
                }, buttonSystemImage: "checkmark", backGroundColor: Color(.systemGreen), maxWidth: false)
                
                ActionImageButton(label: "", action: {
                    viewModel.setChangeLettersMode(mode: false)
                }, buttonSystemImage: "arrowshape.turn.up.backward.fill", backGroundColor: Color(.systemGray), maxWidth: false)
            } else {
                ActionImageButton(label: "", action: {
                    viewModel.setChangeLettersMode(mode: true)
                }, buttonSystemImage: "arrow.2.circlepath", backGroundColor: Color(.systemOrange), maxWidth: false)
                
                ActionImageButton(label: "", action: {
                    await viewModel.validateMove(gameId: game.id)
                }, buttonSystemImage: "questionmark", backGroundColor: Color(.systemGray), maxWidth: false)
                
                ActionImageButton(label: "", action: {
                    do {
                        try await viewModel.submitMove(gameId: game.id)
                    } catch {
                        print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                    }
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
                }
            }, buttonSystemImage: "figure.walk.motion", backGroundColor: Color(.systemRed), maxWidth: false)
        }
    }
    
    var body: some View {
        ZStack {
            if let game = viewModel.game {
                if isLandscape {
                    VStack(alignment: .trailing, spacing: 12) {
                        // TODO: Spacer() has no effect here! Check why...
                        playerList(game: game)
                            .frame(maxWidth: .infinity)
                        
                        if !isInChangeLetterMode {
                            exitGameButtons(game: game)
                        }
                        
                        if hasTurn {
                            hasTurnButtons(game: game, isInChangeLetterMode: isInChangeLetterMode)
                        }
                    }
                    .padding()
                } else {
                    HStack(alignment: .top, spacing: 12) {
                        playerList(game: game)
                            .frame(maxWidth: mainWindowSize.width / 2)
                        
                        if !isInChangeLetterMode {
                            Spacer()
                            
                            exitGameButtons(game: game)
                        }
                        
                        Spacer()
                        
                        hasTurnButtons(game: game, isInChangeLetterMode: isInChangeLetterMode)
                    }
                    .padding()
                }
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

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        let boardViewModel = BoardViewModel()
        let rackViewModel = RackViewModel()
        CommandView(gameId: "fake_id", commandViewModel: CommandViewModel(boardViewModel: boardViewModel, rackViewModel: rackViewModel))
    }
}
