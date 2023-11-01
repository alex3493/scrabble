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
    let maxWidth: Bool
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack {
                Group {
                    Text(label)
                        .fontWeight(.semibold)
                        .font(.system(size: 10))
                    Image(systemName: buttonSystemImage)
                }
            }
            .foregroundColor(.white)
            // TODO: UIScreen doesn't work when screen is rotated.
            // .frame(/* width: maxWidth ? UIScreen.main.bounds.width - 32 : nil,*/ height: 24)
            .padding(.all, 4)
            .padding(.horizontal, 6)
        }
        .background(backGroundColor)
        .cornerRadius(10)
        .padding(.top, 0)
    }
}

#Preview {
    ActionButton(label: "Label", action: {}, buttonSystemImage: "arrow.right", backGroundColor: Color(.systemBlue), maxWidth: true)
}
