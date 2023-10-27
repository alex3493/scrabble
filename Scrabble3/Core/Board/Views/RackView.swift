//
//  RackView.swift
//  Scrabble3
//
//  Created by Alex on 27/10/23.
//

import SwiftUI

struct RackView: View {
    
    @Environment(\.mainWindowSize) var mainWindowSize
    
    var body: some View {
        Text("Rack view: \(mainWindowSize.width) / \(mainWindowSize.height)")
    }
}

#Preview {
    RackView()
}
