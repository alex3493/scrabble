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
                                            // ProgressView()
                                        }
                                    )
                                    
                                }
                            }
                        }
                    }
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
            
            Button {
                isPresented = false
            } label: {
                HStack(spacing: 3) {
                    Text("ЗАКРЫТЬ")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
            .padding()
        }
    }
}

#Preview {
    MoveInfoDialogView(words: [("Word", WordInfo(term: "Word", definition: "Definition"), 10)], score: 10, bonus: nil, isPresented: .constant(false))
}
