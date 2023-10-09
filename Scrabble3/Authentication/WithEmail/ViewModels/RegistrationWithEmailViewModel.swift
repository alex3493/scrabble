//
//  SignUpWithEmailViewModel.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import Foundation

@MainActor
final class RegistrationWithEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    
    func signUp() async throws {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !name.isEmpty else {
            print("Required data missing.")
            return
        }
        
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        
        // TODO: add "name" parameter to init.
        let user = DBUser(auth: authDataResult)
        
        try await UserManager.shared.createNewUser(user: user)
        
    }
}
