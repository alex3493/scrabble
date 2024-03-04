//
//  UserManager.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

struct DBUser: Codable, Hashable, Identifiable {
    let userId: String
    let email: String?
    let dateCreated: Date?
    let name: String?
    
    var id: String {
        return userId
    }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case dateCreated = "date_created"
        case name
    }
    
    init(auth: AuthDataResultModel) {
        self.userId = auth.uid
        self.email = auth.email
        self.dateCreated = Date()
        self.name = auth.email
    }
    
    init(auth: AuthDataResultModel, name: String?) {
        self.init(userId: auth.uid, email: auth.email, dateCreated: Date(), name: name)
    }
    
    init(
        userId: String,
        email: String?,
        dateCreated: Date?,
        name: String?
    ) {
        self.userId = userId
        self.email = email
        self.dateCreated = dateCreated
        self.name = name
    }
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: name ?? "") {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        return ""
    }
    
    var lookupKeywords: [String] {
        [generateLookupKeywords(term: email), generateLookupKeywords(term: name)].flatMap { $0 }
    }
    
    private func generateLookupKeywords(term: String?) -> [String] {
        guard let term = term, !term.isEmpty else { return [] }
        
        var keywords: [String] = []
        
        for i in 1...term.count {
            keywords.append(String(term.prefix(i)))
        }
        
        return keywords
    }
    
}

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    private var contactsListener: ListenerRegistration? = nil
    
    private let encoder: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let decoder: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createNewUser(user: DBUser) async throws {
        let document = userDocument(userId: user.userId)
        try document.setData(from: user, merge: false)
        try await document.updateData(["lookup_keywords" : user.lookupKeywords])
        
        // try userDocument(userId: user.userId).setData(from: user, merge: false)
    }
    
    func deleteUser(userId: String) {
        userDocument(userId: userId).delete()
    }
    
    // TODO: add function to update db user.
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
    // We have to order by email, otherwise we cannot exclude contacted users from the query.
    func getUsers(limit: Int, excludeEmails: [String], lookupQuery: String?, afterDocument: DocumentSnapshot?) async throws -> (items: [DBUser], lastDocument: DocumentSnapshot?) {
        
        let query = userCollection
            .order(by: DBUser.CodingKeys.email.rawValue, descending: false)
            .whereField(DBUser.CodingKeys.email.rawValue, notIn: excludeEmails)
        
        if let lookupQuery = lookupQuery {
            query.whereField("lookup_keywords", arrayContains: lookupQuery)
        }
        
        return try await query
            .limit(to: limit)
            .startOptionally(afterDocument: afterDocument)
            .getDocumentsWithSnapshot(as: DBUser.self)
    }
    
    func getUsers(withIds: [String]) async throws -> [DBUser] {
        guard withIds.count > 0 else { return [] }
        
        return try await userCollection
            .order(by: DBUser.CodingKeys.name.rawValue, descending: false)
            .whereField(DBUser.CodingKeys.userId.rawValue, in: withIds)
            .getDocuments(as: DBUser.self)
    }
    
    // User contacts management.
    
    private let allUserContactCollection = Firestore.firestore().collection("user_contacts")
    
    private func userContactDocument(contactId: String) -> DocumentReference {
        return allUserContactCollection.document(contactId)
    }
    
    func userContactCollection(user: DBUser) -> Query {
        return allUserContactCollection
            .whereFilter(Filter.orFilter([
                Filter.whereField(UsersLinkModel.CodingKeys.initiatorUserId.rawValue, isEqualTo: user.userId),
                Filter.whereField(UsersLinkModel.CodingKeys.counterpartUserId.rawValue, isEqualTo: user.userId)
            ]))
    }
    
    func addContactRequest(initiatorUser: DBUser, counterpartUser: DBUser) async throws {
        
        print("Adding contact request", initiatorUser.email!, counterpartUser.email!)
        
        let contact = UsersLinkModel(initiatorUserId: initiatorUser.userId, counterpartUserId: counterpartUser.userId, contactConfirmed: false)
        
        let document = userContactDocument(contactId: contact.id)
        
        try document.setData(from: contact, merge: false, encoder: encoder)
    }
    
    func acceptContactRequest(id: String) async throws {
        let document = allUserContactCollection.document(id)
        
        var contact = try await document.getDocument(as: UsersLinkModel.self)
        contact = contact.confirmContact()
        
        try document.setData(from: contact, merge: false, encoder: encoder)
        
    }
    
    func deleteContact(id: String) async throws {
        print("UserManager :: delete contact: ", id)
        try await userContactDocument(contactId: id).delete()
    }
    
    func addListenerForContacts(user: DBUser) -> AnyPublisher<[UsersLinkModel], Error> {
        let (publisher, listener) = userContactCollection(user: user)
            .addListSnapshotListener(as: UsersLinkModel.self)
        
        self.contactsListener = listener
        return publisher
    }
    
    func removeListenerForContacts() {
        contactsListener?.remove()
    }
    
}

