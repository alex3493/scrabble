//
//  UsersLinkModel.swift
//  Scrabble3
//
//  Created by Alex on 15/11/23.
//

import Foundation

import Firebase


struct UsersLinkModel: Identifiable, Codable {
    var id: String {
        return ("\(initiatorUserId)::\(counterpartUserId)")
    }
    
    let initiatorUserId: String
    let counterpartUserId: String
    
    let contactConfirmed: Bool
    let updatedAt: Timestamp
    
    init(initiatorUserId: String, counterpartUserId: String, contactConfirmed: Bool) {
        self.initiatorUserId = initiatorUserId
        self.counterpartUserId = counterpartUserId
        self.contactConfirmed = contactConfirmed
        self.updatedAt = Timestamp()
    }
    
    enum CodingKeys: String, CodingKey {
        case initiatorUserId = "initiator_user_id"
        case counterpartUserId = "counterpart_user_id"
        case contactConfirmed = "contact_confirmed"
        case updatedAt = "updated_at"
    }
    
    func confirmContact() -> Self {
        return UsersLinkModel(initiatorUserId: self.initiatorUserId, counterpartUserId: self.counterpartUserId, contactConfirmed: true)
    }
}
