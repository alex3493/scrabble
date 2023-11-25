//
//  GameListViewModel.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import Foundation
import Combine

@MainActor
final class GameListViewModel: ObservableObject {
    
    @Published private(set) var games: [GameModel] = []
    @Published private(set) var archivedGames: [GameModel] = []
    private var cancellables = Set<AnyCancellable>()
    
    var currentUser: DBUser? = nil
    
    @Published private(set) var userContactsViewModel = UserContactsViewModel()
    
    var preferredLanguage: GameLanguage? = nil
    
    func addListenerForGames(lang: GameLanguage) {
        guard let currentUser else { return }
        
        // Only act if preferred language has changed, otherwise we may encounter infinite update loop.
        guard lang.rawValue != preferredLanguage?.rawValue else { return }
        preferredLanguage = lang
        
        // Remove existing listener (if any).
        removeListenerForGames()
        
        // Read contact users for view model store.
        let contactUsers = userContactsViewModel.contactUsers
        
        let confirmedContacts = contactUsers.filter { $0.contactConfirmed == true }
        
        let initiatorEmails = confirmedContacts.map { $0.initiatorUser.email ?? "" }
        let counterpartEmails = confirmedContacts.map { $0.counterpartUser.email ?? "" }
        
        // Always list games created by me, even if no other players are connected.
        let emails = Array(Set(initiatorEmails + counterpartEmails + [currentUser.email ?? ""]))
        
        GameManager.shared.addListenerForGames(includeEmails: emails, lang: lang)
            .sink { completion in
                
            } receiveValue: { [weak self] games in
                print("GAMES LISTENER :: Game list updated. Games count: \(games.count)")
                self?.games = games
            }
            .store(in: &cancellables)
    }
    
    func addListenerForContacts(lang: GameLanguage) {
        guard let currentUser else { return }
        
        UserManager.shared.addListenerForContacts(user: currentUser)
            .sink { completion in
                
            } receiveValue: { [weak self] contacts in
                print("CONTACTS LISTENER :: Contact list updated. Contacts count: \(contacts.count)")
                
                let requestIds = contacts.map { $0.counterpartUserId }
                let mentionIds = contacts.map { $0.initiatorUserId }
                let ids = requestIds + mentionIds
                
                Task {
                    let users = try await UserManager.shared.getUsers(withIds: ids)
                    let usersDict = Dictionary(uniqueKeysWithValues: users.lazy.map { ($0.userId, $0) })
                    
                    var contactUsers: [UserContact] = []
                    contacts.forEach { linkModel in
                        contactUsers.append(UserContact(contactLink: linkModel, initiatorUser: usersDict[linkModel.initiatorUserId]!, counterpartUser: usersDict[linkModel.counterpartUserId]!))
                    }
                    
                    self?.userContactsViewModel.contactUsers = contactUsers
                    
                    // Once we have contacts loaded we can refresh games listener.
                    self?.addListenerForGames(lang: lang)
                }
            }
            .store(in: &cancellables)
    }
    
    func removeListenerForGames() {
        GameManager.shared.removeListenerForGames()
    }
    
    func removeListenerForContacts() {
        UserManager.shared.removeListenerForContacts()
    }
    
    deinit {
        print("***** GameListViewModel DESTROYED")
    }
    
    // TODO: just testing resource access.
    //    func test() throws {
    //        let url = Bundle.main.url(forResource: "russian", withExtension: "dic", subdirectory: "Dic")
    //        if let url = url, try url.checkResourceIsReachable() {
    //            print("file exist")
    //            if let fileContents = try? String(contentsOf: url) {
    //                // we loaded the file into a string!
    //                print("file loaded")
    //                print("Content:", fileContents)
    //            }
    //        } else {
    //            print("file is not found")
    //        }
    //
    //    }
}
