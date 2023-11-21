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
    
    @Published var contactUsers: [UserContact] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: DBUser? = nil
    
//    init(contactUsers: [UserContact]) {
//        print("UserContactsViewModel INIT", contactUsers.count)
//        self.contactUsers = contactUsers
//    }
    
    func deleteContact(id: String) async throws {
        print("Deleting contact: ", id)
        try await UserManager.shared.deleteContact(id: id)
    }
    
    func acceptContact(id: String) async throws {
        print("Accepting contact: ", id)
        try await UserManager.shared.acceptContactRequest(id: id)
    }
    
}
