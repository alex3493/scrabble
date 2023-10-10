//
//  LoginView.swift
//  Scrabble3
//
//  Created by Alex on 7/10/23.
//

import SwiftUI

struct LoginView: View {
    
    // @StateObject private var viewModel = LoginWithEmailViewModel()
    
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    var body: some View {
        NavigationStack {
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
                    TextInputView(text: $viewModel.password, title: "Password", placeholder: "Enter your password...", isSecureField: true)
                    
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                Button {
                    print("Log in action here...")
                } label: {
                    HStack {
                        Text("SIGN IN")
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
                
                NavigationLink {
                    RegistrationView()
                        .navigationBarBackButtonHidden()
                } label: {
                    HStack(spacing: 3) {
                        Text("Don't have an account?")
                        Text("Sign up")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    }
                    .font(.system(size: 14))
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthWithEmailViewModel())
}
