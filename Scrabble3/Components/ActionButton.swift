//
//  ActionButton.swift
//  Scrabble3
//
//  Created by Alex on 22/10/23.
//

import SwiftUI

struct ActionButton: View {
    let label: String
    let action: () async -> Void
    let buttonSystemImage: String
    let backGroundColor: Color
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                Text(label)
                    .fontWeight(.semibold)
                Image(systemName: buttonSystemImage)
            }
            .foregroundColor(.white)
            .frame(width: UIScreen.main.bounds.width - 32, height: 48)
        }
        .background(backGroundColor)
        .cornerRadius(10)
        .padding(.top, 0)
    }
}

#Preview {
    ActionButton(label: "Label", action: {}, buttonSystemImage: "arrow.right", backGroundColor: Color(.systemBlue))
}
