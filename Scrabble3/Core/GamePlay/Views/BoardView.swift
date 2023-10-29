//
//  BoardView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct BoardView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    @StateObject private var viewModel = BoardViewModel.shared
    
    var body: some View {
        Text("Board view: \(mainWindowSize.width) / \(mainWindowSize.height)")
    }
}

#Preview {
    BoardView()
}
