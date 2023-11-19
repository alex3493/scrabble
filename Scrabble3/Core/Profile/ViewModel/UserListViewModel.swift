//
//  UserListViewModel.swift
//  Scrabble3
//
//  Created by Alex on 15/11/23.
//

import Foundation
import FirebaseFirestore

struct UserWithContactData: Identifiable, Equatable {
    static func == (lhs: UserWithContactData, rhs: UserWithContactData) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(user: DBUser, contactLink: UsersLinkModel?, isIncomingContact: Bool = false) {
        self.user = user
        self.contactLink = contactLink
        self.isIncomingContact = isIncomingContact
    }
    
    let user: DBUser
    
    var id: String {
        return user.userId
    }
    
    let contactLink: UsersLinkModel?
    
    var isContact: Bool {
        return contactLink != nil
    }
    
    var isContactConfirmed: Bool {
        return contactLink?.contactConfirmed ?? false
    }
    
    let isIncomingContact: Bool
    
    var name: String {
        return user.name ?? email
    }
    
    var email: String {
        return user.email ?? ""
    }
}

@MainActor
class UserListViewModel: ObservableObject {
    
    @Published private(set) var users: [UserWithContactData] = []
    
    var contacts: [UserContact] = []
    
    var lastDocument: DocumentSnapshot? = nil
    
    var allUsersFetched: Bool = false
    
    var currentUser: DBUser? = nil
    
    init() {
        print("UserListViewModel INIT")
    }
    
    func fetchUsers() async throws {
        let (newUsers, lastDocument) = try await UserManager.shared.getUsers(limit: 3, afterDocument: lastDocument)
        
        var newUsersWithContactData: [UserWithContactData] = []
        
        // We absolutely need current user here.
        if let currentUser {
            
            let contactedByMe = contacts.filter { $0.isUserInitiator(user: currentUser) }
            let contactedToMe = contacts.filter { $0.isUserCounterpart(user: currentUser) }
            
            let contactedByMeDict = Dictionary(uniqueKeysWithValues: contactedByMe.lazy.map { ($0.counterpartUser.userId, $0) })
            let contactedToMeDict = Dictionary(uniqueKeysWithValues: contactedToMe.lazy.map { ($0.initiatorUser.userId, $0) })
            
            newUsers.forEach { user in
                if let outgoingContact = contactedByMeDict[user.userId] {
                    newUsersWithContactData.append(UserWithContactData(user: user, contactLink: UsersLinkModel(initiatorUserId: currentUser.userId, counterpartUserId: user.userId, contactConfirmed: outgoingContact.contactConfirmed), isIncomingContact: false))
                } else if let incomingContact = contactedToMeDict[currentUser.userId] {
                    newUsersWithContactData.append(UserWithContactData(user: user, contactLink: UsersLinkModel(initiatorUserId: user.userId, counterpartUserId: currentUser.userId, contactConfirmed: incomingContact.contactConfirmed), isIncomingContact: true))
                } else {
                    newUsersWithContactData.append(UserWithContactData(user: user, contactLink: nil))
                }
            }
        }
        
        users.append(contentsOf: newUsersWithContactData)
        
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
    
    func acceptContact(id: String) async throws {
        print("Accepting contact: ", id)
        try await UserManager.shared.acceptContactRequest(id: id)
    }
    
    func deleteContact(id: String) async throws {
        print("Deleting contact: ", id)
        try await UserManager.shared.deleteContact(id: id)
    }
}
