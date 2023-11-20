//
//  UserContactsViewModel.swift
//  Scrabble3
//
//  Created by Alex on 16/11/23.
//

import Foundation
import Combine

struct UserContact: Identifiable {
    var id: String {
        return contactLink.id
    }
    
    let contactLink: UsersLinkModel
    
    let initiatorUser: DBUser
    let counterpartUser: DBUser
    
    var contactConfirmed: Bool {
        return contactLink.contactConfirmed
    }
    
    func isIncomingContact(currentUserId: String) -> Bool {
        return contactLink.counterpartUserId == currentUserId
    }
    
    func displayContact(currentUserId: String) -> DBUser {
        return isIncomingContact(currentUserId: currentUserId) ? initiatorUser : counterpartUser
    }
    
    var canAcceptContact: Bool {
        return !contactConfirmed
    }
    
}

@MainActor
class UserContactsViewModel: ObservableObject {
    
    @Published private(set) var contactUsers: [UserContact] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: DBUser? = nil
    
    func addListenerForContacts() {
        guard let currentUser else { return }
        
        UserManager.shared.addListenerForContacts(user: currentUser)
            .sink { completion in
                
            } receiveValue: { [weak self] contacts in
                print("CONTACTS LISTENER :: Contact list updated. Contacts count: \(contacts.count)")
                
                let requestIds = contacts.map { $0.counterpartUserId }
                
                let mentionIds = contacts.map { $0.initiatorUserId }
                
                let ids = requestIds + mentionIds
                
                Task {
                    if ids.count > 0 {
                        let users = try await UserManager.shared.getUsers(withIds: ids)
                        
                        let usersDict = Dictionary(uniqueKeysWithValues: users.lazy.map { ($0.userId, $0) })
                        
                        var contactUsers: [UserContact] = []
                          
                        contacts.forEach { linkModel in
                            contactUsers.append(UserContact(contactLink: linkModel, initiatorUser: usersDict[linkModel.initiatorUserId]!, counterpartUser: usersDict[linkModel.counterpartUserId]!))
                        }
                        
                        self?.contactUsers = contactUsers
                    } else {
                        self?.contactUsers = []
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func deleteContact(id: String) async throws {
        print("Deleting contact: ", id)
        try await UserManager.shared.deleteContact(id: id)
    }
    
    func acceptContact(id: String) async throws {
        print("Accepting contact: ", id)
        try await UserManager.shared.acceptContactRequest(id: id)
    }
    
}
