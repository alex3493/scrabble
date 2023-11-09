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
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: DBUser?
    
    init() {
        userSession = Auth.auth().currentUser
        
        Task {
            try? await fetchUser()
        }
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            print("No email or password found.")
            return
        }
        
        let authDataResult = try await AuthenticationManager.shared.signInUser(email: email, password: password)
        
        userSession = authDataResult.user
        
        try? await fetchUser()
    }
    
    func createUser(email: String, password: String, confirmPassword: String, name: String) async throws {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !name.isEmpty else {
            print("Required data missing.")
            return
        }
        
        let authDataResult = try await AuthenticationManager.shared.createUser(withEmail: email, password: password)
        
        let user = DBUser(auth: authDataResult, name: name)
        
        try await UserManager.shared.createNewUser(user: user)
        
        userSession = authDataResult.user
        try? await fetchUser()
    }
    
    func updatePassword(newPassword: String, currentPassword: String) async -> Bool {
        guard let userSession = userSession else { return false }
        guard let email = userSession.email else { return false }
        
        do {
            try await AuthenticationManager.shared.signInUser(email: email, password: currentPassword)
            try await AuthenticationManager.shared.updatePassword(password: newPassword)
        } catch {
            return false
        }
        
        return true
    }
    
    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            clearUser()
        } catch {
            print("DEBUG :: Error signing out user: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() {
        guard let userSession = userSession else { return }
        
        AuthenticationManager.shared.deleteAccount()
        UserManager.shared.deleteUser(userId: userSession.uid)
        
        clearUser()
    }
    
    func fetchUser() async throws {
        guard let userId = userSession?.uid else { return }
        
        currentUser = try? await UserManager.shared.getUser(userId: userId)
    }
    
    func clearUser() {
        userSession = nil
        currentUser = nil
    }
}
