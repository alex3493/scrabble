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
            .padding(.all, 4)
            .padding(.horizontal, 6)
        }
        .background(backGroundColor)
        .cornerRadius(10)
        .padding(.top, 0)
    }
}

struct ActionImageButton: View {
    let label: String
    let action: () async -> Void
    let buttonSystemImage: String
    let backGroundColor: Color
    let maxWidth: Bool
    var disabled: Bool = false
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            if label == "" {
                Image(systemName: buttonSystemImage)
                    .resizable()
                    .scaledToFit()
                    .padding(.all, 10)
                    .foregroundColor(.white)
                    // TODO: make it dependant from screen resolution.
                    .frame(width: 40, height: 40)
            } else {
                HStack {
                    Group {
                        Text(label)
                            .fontWeight(.semibold)
                            .font(.system(size: 10))
                        Image(systemName: buttonSystemImage)
                    }
                }
                .foregroundColor(.white)
                .padding(.all, 4)
                .padding(.horizontal, 6)
            }
        }
        .background(backGroundColor)
        .cornerRadius(10)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}

#Preview {
    ActionButton(label: "Label", action: {}, buttonSystemImage: "arrow.right", backGroundColor: Color(.systemBlue), maxWidth: true)
}
