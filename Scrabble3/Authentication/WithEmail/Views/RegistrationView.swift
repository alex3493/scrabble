//
//  RegistrationView.swift
//  Scrabble3
//
//  Created by Alex on 7/10/23.
//

import SwiftUI

struct RegistrationView: View {
    
    // @StateObject private var viewModel = RegistrationWithEmailViewModel()
    
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Image(systemName: "swift")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .padding(.vertical, 32)
                .foregroundStyle(.cyan)
            VStack(spacing: 12) {
                TextInputView(text: $viewModel.email, title: "Email", placeholder: "name@example.com")
                    .autocapitalization(.none)
                TextInputView(text: $viewModel.name, title: "Name", placeholder: "Enter your name...", isSecureField: false)
                TextInputView(text: $viewModel.password, title: "Password", placeholder: "Enter your password...", isSecureField: true)
                TextInputView(text: $viewModel.confirmPassword, title: "Confirm Password", placeholder: "Confirm password...", isSecureField: true)
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            Button {
                Task {
                    try await viewModel.createUser()
                }
            } label: {
                HStack {
                    Text("SIGN UP")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color(.systemBlue))
            .cornerRadius(10)
            .padding(.top, 24)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    Text("Sign in")
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                }
                .font(.system(size: 14))
            }
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthWithEmailViewModel())
}
