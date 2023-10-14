//
//  RegistrationView.swift
//  Scrabble3
//
//  Created by Alex on 7/10/23.
//

import SwiftUI

struct RegistrationView: View {
    
    @State var email: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var name: String = ""
    
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let errorStore = ErrorStore.shared
    
    var body: some View {
        VStack {
            Image(systemName: "swift")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .padding(.vertical, 32)
                .foregroundStyle(.cyan)
            VStack(spacing: 12) {
                TextInputView(text: $email, title: "Email", placeholder: "name@example.com")
                    .autocapitalization(.none)
                TextInputView(text: $name, title: "Name", placeholder: "Enter your name...", isSecureField: false)
                TextInputView(text: $password, title: "Password", placeholder: "Enter your password...", isSecureField: true)
                TextInputView(text: $confirmPassword, title: "Confirm Password", placeholder: "Confirm password...", isSecureField: true)
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            Button {
                Task {
                    do {
                        try await viewModel.createUser(email: email, password: password, confirmPassword: confirmPassword, name: name)
                    } catch {
                        print("DEBUG :: Error creating account: \(error.localizedDescription)")
                        errorStore.showRegistrationAlertView(withMessage: error.localizedDescription)
                    }
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
