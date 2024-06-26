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
    
    var contacts: [UserContact] = []
    
    var lastDocument: DocumentSnapshot? = nil
    
    var allUsersFetched: Bool = false
    
    var searchQuery: String = ""
    
    var currentUser: DBUser? = nil
    
    init() {
        print("UserListViewModel INIT")
    }
    
    func fetchUsers(reload: Bool = false, query: String = "") async throws {
        if reload {
            lastDocument = nil
            users = []
            allUsersFetched = false
        }
        
        print("Fetching users", reload)
        
        if let currentUser {
            let contactedByMeEmails = contacts.compactMap { $0.counterpartUser.email }
            let contactedToMeEmails = contacts.compactMap { $0.initiatorUser.email }
            
            var excludeEmails = contactedByMeEmails + contactedToMeEmails
            
            excludeEmails.append(currentUser.email ?? "")
            
            let (newUsers, lastDocument) = try await UserManager.shared.getUsers(limit: 10, excludeEmails: excludeEmails, lookupQuery: query, afterDocument: lastDocument)
            
            users.append(contentsOf: newUsers)
            
            if let lastDocument {
                self.lastDocument = lastDocument
            } else {
                allUsersFetched = true
            }
        }
    }
    
    func addContactRequest(targetUser: DBUser) async throws {
        guard let currentUser else { return }
        
        try await UserManager.shared.addContactRequest(initiatorUser: currentUser, counterpartUser: targetUser)
        
    }
    
    public func performSearch() async throws {
        print("Performing search for: \(searchQuery)")
        
        try await fetchUsers(reload: true, query: searchQuery)
    }
    
    public func resetSearch() async throws {
        searchQuery = ""
        try await fetchUsers(reload: true, query: "")
    }
}
