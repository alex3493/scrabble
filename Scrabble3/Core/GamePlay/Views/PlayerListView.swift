//
//  PlayerListView.swift
//  Scrabble3
//
//  Created by Alex on 8/12/23.
//

import SwiftUI
import Firebase

struct PlayerListView: View {
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @StateObject private var viewModel: CommandViewModel
    
    init(viewModel: CommandViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        if let game = viewModel.game {
            VStack(spacing: 12) {
                ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 12) {
                        Image(systemName: game.turn == index ? "person.fill" : "person")
                        Text(item.user.initials)
                        Spacer()
                        Text("\(item.score)")
                        
                        // For current turn player we show provisional score (current move).
                        if game.turn == index, item.id == authViewModel.currentUser?.userId, !viewModel.tempScores.isEmpty, let tempScore = viewModel.tempScores[index] {
                            
                            if tempScore == -1 {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                            } else if tempScore > 0 {
                                Text("+\(tempScore)")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    Divider()
                }
                if game.rules == .express {
                    HStack {
                        // TODO: refactor - make max rounds configurable.
                        Text("Rounds left: \(6 - game.partialMoveRounds)")
                            .foregroundStyle(game.partialMoveRounds == 5 ? .red : .black)
                        Spacer()
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }
}

struct PlayerListView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerListView(viewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
    }
}
