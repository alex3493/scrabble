//
//  GameResultView.swift
//  Scrabble3
//
//  Created by Alex on 12/11/23.
//

import SwiftUI

struct GameResultView: View {
    
    @StateObject private var viewModel = GameInfoViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let errorStore = ErrorStore.shared
    
    let game: GameModel
    
    @State var currentUser: DBUser? = nil
    
    @State var gameMoves: [String: [MoveModel]] = [:]
    
    // @State var gameWords: [String: [WordModel]] = [:]
    
    var body: some View {
        VStack {
            List {
                Section("Игра") {
                    Text("\(game.creatorUser.name!): \(Utils.formatTransactionTimestamp(game.createdAt))")
                    Text("Current game status: \(game.gameStatus.rawValue)")
                }
                
                if let winners = winners, game.gameStatus == .finished {
                    Section(winners.count > 1 ? "Победители" : "Победитель") {
                        ForEach(winners, id: \.id.self) { item in
                            HStack(spacing: 12) {
                                Text(item.user.name!)
                                Spacer()
                                Text("\(item.score)")
                            }
                            .padding()
                        }
                        .background(Color.green)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                }
                
                Section("Игроки") {
                    ForEach(Array(game.players.enumerated()), id: \.offset) { index, item in
                        VStack {
                            HStack(spacing: 12) {
                                Text(item.user.name!)
                                Spacer()
                                Text("\(item.score)")
                            }
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.yellow)
                            if !getPlayerMoves(playerId: item.id).isEmpty {
                                ForEach(Array(getPlayerMoves(playerId: item.id).enumerated()), id: \.offset) { index, move in
                                    Divider()
                                    if move.words.count > 0 {
                                        VStack {
                                            ForEach(move.words, id: \.self) { word in
                                                HStack {
                                                    Text(word.word)
                                                    Spacer()
                                                    Text("\(word.score)")
                                                }
                                            }
                                            if move.hasBonus {
                                                HStack {
                                                    Text("Бонус")
                                                        .italic()
                                                    Spacer()
                                                    Text("\(Constants.Game.bonusFullRackMove)")
                                                }
                                            }
                                            HStack {
                                                Spacer()
                                                Text("\(move.score)")
                                                    .fontWeight(.bold)
                                            }
                                        }
                                    } else {
                                        HStack {
                                            Spacer()
                                            Text("Ход пропущен")
                                                .italic()
                                        }
                                    }
                                }
                            } else {
                                Text("Игрок не сделал ни одного хода")
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
            .padding()
            
            Spacer()
            
            if canDeleteGame {
                ActionButton(label: "УДАЛИТЬ ИГРУ", action: {
                    do {
                        try await viewModel.deleteGame(gameId: game.id)
                        dismiss()
                    } catch {
                        print("DEBUG :: Error deleting game: \(error.localizedDescription)")
                        errorStore.showGameSetupAlertView(withMessage: error.localizedDescription)
                    }
                }, buttonSystemImage: "trash", backGroundColor: Color(.systemRed), maxWidth: true)
            }
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Все игры")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
                .font(.system(size: 14))
            }
            .padding()
        }
        .onAppear() {
            currentUser = authViewModel.currentUser
        }
        .task {
            do {
                try await fetchGameMoves()
            } catch {
                print("DEBUG :: Error fetching game moves", error.localizedDescription)
            }
        }
    }
    
    var canDeleteGame: Bool {
        return game.creatorUser.userId == currentUser?.userId
    }
    
    var maxScore: Int? {
        return game.players.max(by: { $0.score < $1.score })?.score
    }
    
    var winners: [Player]? {
        
        if let maxScore = game.players.max(by: { $0.score < $1.score })?.score {
            let winnerPlayers = game.players.sorted { lhs, rhs in
                return lhs.score < rhs.score
            }
            
            return winnerPlayers.filter { player in
                return player.score == maxScore
            }
        }
        
        return nil
    }
    
    func fetchGameMoves() async throws {
        gameMoves = [:]
        
        let moves = try await MoveManager.shared.getGameMoves(gameId: game.id).getDocuments(as: MoveModel.self)
        
        game.players.forEach { player in
            gameMoves[player.id] = moves.filter { $0.user.userId == player.id }
        }
    }
    
//    func fetchGameWords() async throws {
//        gameWords = [:]
//        
//        let moves = try await MoveManager.shared.getGameMoves(gameId: game.id).getDocuments(as: MoveModel.self)
//        
//        game.players.forEach { player in
//            let playerMoves = moves.filter { $0.user.userId == player.id }
//            gameWords[player.id] = playerMoves.flatMap{ $0.words }
//        }
//    }
    
//    func getPlayerWords(playerId: String) -> [WordModel] {
//        guard !gameWords.isEmpty, let words = gameWords[playerId] else { return [] }
//        
//        return words
//    }
    
    func getPlayerMoves(playerId: String) -> [MoveModel] {
        guard !gameMoves.isEmpty, let moves = gameMoves[playerId] else { return [] }
        
        // Order ascending.
        return moves.sorted { lhs, rhs in
            return lhs.createdAt < rhs.createdAt
        }
    }
}

import FirebaseFirestore
import FirebaseFirestoreSwift

struct GameResultView_Previews: PreviewProvider {
    static var previews: some View {
        let uuid = UUID().uuidString
        let user = DBUser(userId: UUID().uuidString, email: "email@example.com", dateCreated: Date(), name: "Test user")
        GameResultView(game: GameModel(id: uuid, createdAt: Timestamp(), creatorUser: user, lang: GameLanguage.ru, players: [Player(user: user, score: 0, letterRack: [])], turn: 0))
    }
}
