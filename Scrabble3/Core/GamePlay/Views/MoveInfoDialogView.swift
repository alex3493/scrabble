//
//  MoveStatisticsView.swift
//  Scrabble3
//
//  Created by Alex on 3/11/23.
//

import SwiftUI

struct MoveInfoDialogView: View {
    
    let words: [(String, WordInfo?, Int)]
    let score: Int?
    let bonus: Int?
    
    let commandViewModel: CommandViewModel
    
    let errorStore = ErrorStore.shared
    
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            List {
                if let totalScore = score {
                    HStack {
                        Text("Всего")
                        Spacer()
                        Text("\(totalScore + (bonus ?? 0))")
                    }
                    .fontWeight(.bold)
                    .padding(.bottom, 12)
                    .padding(.top, 10)
                }
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    VStack {
                        HStack {
                            Text("\(word.0)")
                            Spacer()
                            Text("\(word.2)")
                        }
                        if let wordInfo = word.1 {
                            HStack {
                                Text("\(wordInfo.definition)")
                                Spacer()
                                if let imageUrl = wordInfo.imageURL {
                                    AsyncImage(
                                        url: URL(string: imageUrl),
                                        content: { image in
                                            image.resizable()
                                                .scaledToFit()
                                                .frame(maxWidth: 100, maxHeight: 100)
                                        },
                                        placeholder: {
                                            ProgressView()
                                        }
                                    )
                                    
                                }
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                }
                if let bonus = bonus {
                    HStack {
                        Text("Премия")
                        Spacer()
                        Text("\(bonus)")
                    }
                    .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            HStack {
                Button {
                    isPresented = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .scaledToFit()
                        Text("ВЕРНУТЬСЯ")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 24))
                }
                .padding()
                
                Spacer()
                
                if showSubmitButton, let game = commandViewModel.game {
                    Button {
                        Task {
                            do {
                                try await commandViewModel.nextTurn(gameId: game.id)
                            } catch {
                                print("DEBUG :: Error submitting move: \(error.localizedDescription)")
                                errorStore.showGamePlayAlertView(withMessage: error.localizedDescription)
                            }
                            isPresented = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .scaledToFit()
                            Text("ОТПРАВИТЬ")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 24))
                    }
                    .padding()
                }
            }
        }
    }
    
    var showSubmitButton: Bool {
        return score != nil
    }
}

#Preview {
    MoveInfoDialogView(words: [("Word", WordInfo(term: "Word", definition: "Definition"), 10)], score: 10, bonus: nil, commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)), isPresented: .constant(false))
}
