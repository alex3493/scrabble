//
//  ArchivedGameListViewModel.swift
//  Scrabble3
//
//  Created by Alex on 23/11/23.
//

import Foundation
import FirebaseFirestore

@MainActor
class ArchivedGameListViewModel: ObservableObject {
    
    @Published private(set) var games: [GameModel] = []
    
    var lastDocument: DocumentSnapshot? = nil
    
    var allGamesFetched: Bool = false
    
    var contacts: [UserContact] = []
    
    var currentUser: DBUser? = nil
    
    func fetchGames() async throws {
        print("Fetching archived games")
        
        if let currentUser {
            
            let confirmedContacts = contacts.filter { $0.contactConfirmed == true }
            
            let initiatorEmails = confirmedContacts.map { $0.initiatorUser.email ?? "" }
            let counterpartEmails = confirmedContacts.map { $0.counterpartUser.email ?? "" }
            
            // Always list games created by me, even if no other players are connected.
            let emails = Array(Set(initiatorEmails + counterpartEmails + [currentUser.email ?? ""]))
            
            let (newGames, lastDocument) = try await GameManager.shared.getArchivedGames(limit: 2, includeEmails: emails, afterDocument: lastDocument)
            
            games.append(contentsOf: newGames)
            
            if let lastDocument {
                self.lastDocument = lastDocument
            } else {
                allGamesFetched = true
            }
        }
    }
}
