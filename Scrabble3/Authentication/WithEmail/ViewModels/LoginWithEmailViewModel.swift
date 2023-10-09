//
//  LoginWithEmailViewModel.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import Foundation

@MainActor
final class LoginWithEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
        
    }
}
