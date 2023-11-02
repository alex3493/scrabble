//
//  AsteriskDialogView.swift
//  Scrabble3
//
//  Created by Alex on 1/11/23.
//

import SwiftUI

struct AsteriskDialogView: View {
    
    @Binding var asteriskDialogPresented: Bool
    let asteriskRow: Int
    let asteriskCol: Int
    
    var body: some View {
        VStack {
            ForEach (Array(chunks.enumerated()), id: \.offset) { indexI, chunk in
                HStack {
                    ForEach (Array(chunk.enumerated()), id: \.offset) { indexJ, tile in
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.black)
                            Text("\(tile.char)").colorInvert()
                        }
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            let asteriskTile = LetterTile(char: tile.char, score: tile.score, probability: tile.probability, isAsterisk: true, lang: tile.lang)
                            asteriskDialogPresented = false
                            
                            BoardViewModel.shared.setLetterTileByPosition(row: asteriskRow, col: asteriskCol, letterTile: asteriskTile)
                        }
                    }
                }
            }
        }
    }
    
    var letters: [LetterTile] = LetterBank.lettersRu.filter { tile in
        return !tile.isAsterisk
    }
    
    var chunks: [[LetterTile]] {
        return stride(from: 0, to: letters.count, by: 6).map {
            Array(letters[$0 ..< Swift.min($0 + 6, letters.count)])
        }
    }
}

#Preview {
    AsteriskDialogView(asteriskDialogPresented: .constant(false), asteriskRow: 0, asteriskCol: 0)
}
