//
//  CommandView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct CommandView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var body: some View {
        Text("Command view: \(mainWindowSize.width) / \(mainWindowSize.height)")
    }
}

#Preview {
    CommandView()
}
