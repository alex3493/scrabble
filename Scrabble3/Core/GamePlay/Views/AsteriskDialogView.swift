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
    
    @StateObject private var boardViewModel: BoardViewModel
    @StateObject private var commandViewModel: CommandViewModel
    
    init(asteriskDialogPresented: Binding<Bool>, asteriskRow: Int, asteriskCol: Int, commandViewModel: CommandViewModel) {
        self.asteriskRow = asteriskRow
        self.asteriskCol = asteriskCol
        
        _asteriskDialogPresented = asteriskDialogPresented
        _commandViewModel = StateObject(wrappedValue: commandViewModel)
        _boardViewModel = StateObject(wrappedValue: commandViewModel.boardViewModel)
    }
    
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
                            let asteriskTile = LetterTile(char: tile.char, score: tile.score, quantity: tile.quantity, isAsterisk: true, lang: tile.lang)
                            asteriskDialogPresented = false
                            
                            boardViewModel.setLetterTileByPosition(row: asteriskRow, col: asteriskCol, letterTile: asteriskTile)
                            
                            let debounce = Debounce(duration: 1)
                            debounce.submit {
                                Task {
                                    do {
                                        try await commandViewModel.validateMoveWords()
                                    } catch {
                                        // We swallow exception here, later we may change it...
                                        // TODO: this is not OK. We should consume this exception in model in order to update view...
                                        print("DEBUG :: Error during internal validation", error.localizedDescription)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    var letters: [LetterTile] {
        let letterBank = LetterTileBank(lang: boardViewModel.lang).tiles
        
        return letterBank.filter { tile in
            return !tile.isAsterisk
        }
    }
    
    var chunks: [[LetterTile]] {
        return stride(from: 0, to: letters.count, by: 6).map {
            Array(letters[$0 ..< Swift.min($0 + 6, letters.count)])
        }
    }
}

#Preview {
    AsteriskDialogView(asteriskDialogPresented: .constant(false), asteriskRow: 0, asteriskCol: 0, commandViewModel: CommandViewModel(boardViewModel: BoardViewModel(lang: .ru), rackViewModel: RackViewModel(lang: .ru)))
}
