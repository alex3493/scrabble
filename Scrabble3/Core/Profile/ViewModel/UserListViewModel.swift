//
//  UserListViewModel.swift
//  Scrabble3
//
//  Created by Alex on 15/11/23.
//

import Foundation
import FirebaseFirestore

@MainActor
class UserListViewModel: ObservableObject {
    
    @Published private(set) var users: [DBUser] = []
    
    var lastDocument: DocumentSnapshot? = nil
    var allUsersFetched: Bool = false
    
    var currentUser: DBUser? = nil
    
    func fetchUsers() async throws {
        let (newUsers, lastDocument) = try await UserManager.shared.getUsers(limit: 3, afterDocument: lastDocument)
        
        users.append(contentsOf: newUsers)
        
        if let lastDocument {
            self.lastDocument = lastDocument
        } else {
            allUsersFetched = true
        }
    }
    
    func addContactRequest(targetUser: DBUser) async throws {
        print("Add contact with user: ", targetUser.email!)
        
        guard let currentUser else { return }
        
        try await UserManager.shared.addContactRequest(initiatorUser: currentUser, counterpartUser: targetUser)
        
    }
}
