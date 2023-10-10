//
//  UserManager.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct DBUser: Codable, Hashable {
    let userId: String
    let email: String?
    let dateCreated: Date?
    let name: String?
    
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
    
    init(
        userId: String,
        email: String,
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
    
}

extension DBUser {
    static var MOCK_USER = DBUser(userId: UUID().uuidString, email: "test@example.com", dateCreated: Date(), name: "Alex Polonski")
}

final class UserManager {
    
    static let shared = UserManager()
    private init() { }
    
    private let userCollection = Firestore.firestore().collection("users")
    
    private func userDocument(userId: String) -> DocumentReference {
        userCollection.document(userId)
    }
    
    func createNewUser(user: DBUser) async throws {
        try userDocument(userId: user.userId).setData(from: user, merge: false)
    }
    
    // TODO: add function to update db user.
    
    func getUser(userId: String) async throws -> DBUser {
        try await userDocument(userId: userId).getDocument(as: DBUser.self)
    }
    
}

