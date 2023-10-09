//
//  TextInputView.swift
//  Scrabble3
//
//  Created by Alex on 7/10/23.
//

import SwiftUI

struct TextInputView: View {
    @Binding var text: String
    let title: String
    let placeholder: String
    var isSecureField: Bool = false
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .foregroundColor(Color(.darkGray))
                .fontWeight(.semibold)
                .font(.footnote)
            
            if isSecureField {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 14))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 14))
            }
            
            Divider()
        }
    }
}

#Preview {
    TextInputView(text: .constant(""), title: "Email", placeholder: "Type here...")
}
