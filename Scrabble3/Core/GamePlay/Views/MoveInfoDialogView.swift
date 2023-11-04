//
//  MoveStatisticsView.swift
//  Scrabble3
//
//  Created by Alex on 3/11/23.
//

import SwiftUI

struct MoveInfoDialogView: View {
    
    let words: [(String, Int)]
    let score: Int
    let bonus: Int?
    
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            List {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    HStack {
                        Text("\(word.0)")
                        Spacer()
                        Text("\(word.1)")
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
                HStack {
                    Text("Всего")
                    Spacer()
                    Text("\(score + (bonus ?? 0))")
                }
                .fontWeight(.bold)
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
    MoveInfoDialogView(words: [("Word", 10)], score: 10, bonus: nil, isPresented: .constant(false))
}
