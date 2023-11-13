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
    
    // var currentUser: DBUser? = nil
    
    func addListenerForGames() {
        GameManager.shared.addListenerForGames()
            .sink { completion in
                
            } receiveValue: { [weak self] games in
                print("GAMES LISTENER :: Game list updated. Games count: \(games.count)")
                self?.games = games
            }
            .store(in: &cancellables)
    }
    
    func addListenerForArchivedGames() {
        GameManager.shared.addListenerForArchivedGames()
            .sink { completion in
                
            } receiveValue: { [weak self] games in
                print("GAMES LISTENER :: Archived game list updated. Games count: \(games.count)")
                self?.archivedGames = games
            }
            .store(in: &cancellables)
    }
    
    func removeListenerForGames() {
        GameManager.shared.removeListenerForGames()
    }
    
    func removeListenerForArchivedGames() {
        GameManager.shared.removeListenerForGames()
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
