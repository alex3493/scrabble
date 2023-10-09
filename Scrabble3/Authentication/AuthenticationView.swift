//
//  AuthenticationView.swift
//  Scrabble3
//
//  Created by Alex on 7/10/23.
//

import SwiftUI

struct AuthenticationView: View {
    var body: some View {
        VStack {
//            NavigationLink {
//                LoginView()
//            } label: {
//                Text("Sign in with email")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(height: 55)
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//            Spacer()
            LoginView()
        }
        .padding()
        .navigationTitle("Sign In")
    }
}

#Preview {
    AuthenticationView()
}
