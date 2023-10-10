//
//  AuthWithEmailViewModel.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import Foundation
import FirebaseAuth

import Firebase

@MainActor
final class AuthWithEmailViewModel: ObservableObject {
    
    // TODO: check why current user has FirebaseAuth.User? type...
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: DBUser?
    
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    
    func signIn() async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
        
    }
    
    func createUser() async throws {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !name.isEmpty else {
            print("Required data missing.")
            return
        }
        
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        
        // TODO: add "name" parameter to init.
        let user = DBUser(auth: authDataResult)
        
        try await UserManager.shared.createNewUser(user: user)
        
    }
    
    func signOut() {
        
    }
    
    func deleteAccount() {
        
    }
    
    // TODO: check it!
    func fetchUser() async throws -> DBUser {
        let userId = userSession?.uid
        
        return try await UserManager.shared.getUser(userId: userId!)
    }
}
