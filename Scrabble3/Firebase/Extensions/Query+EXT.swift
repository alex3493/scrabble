//
//  Query+EXT.swift
//  Scrabble3
//
//  Created by Alex on 15/10/23.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

extension Query {
    
    func getDocuments<T>(as type: T.Type) async throws -> [T] where T : Decodable {
        try await getDocumentsWithSnapshot(as: type).items
    }
    
    func getDocumentsWithSnapshot<T>(as type: T.Type) async throws -> (items: [T], lastDocument: DocumentSnapshot?) where T : Decodable {
        let snapshot = try await self.getDocuments()
        
        let items = try snapshot.documents.map({ document in
            try document.data(as: T.self)
        })
        
        return (items, snapshot.documents.last)
    }
    
    func startOptionally(afterDocument lastDocument: DocumentSnapshot?) -> Query {
        guard let lastDocument else { return self }
        return self.start(afterDocument: lastDocument)
    }
    
    func aggregateCount() async throws -> Int {
        let snapshot = try await self.count.getAggregation(source: .server)
        return Int(truncating: snapshot.count)
    }
    
    func addListSnapshotListener<T>(as type: T.Type) -> (AnyPublisher<[T], Error>, ListenerRegistration) where T : Decodable {
        let publisher = PassthroughSubject<[T], Error>()
        
        let listener = self.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents")
                return
            }
            
            let items: [T] = documents.compactMap({ try? $0.data(as: T.self) })
            publisher.send(items)
        }
        
        return (publisher.eraseToAnyPublisher(), listener)
    }
    
}

extension DocumentReference {
    func addItemSnapshotListener<T>(as type: T.Type) -> (AnyPublisher<T, Error>, ListenerRegistration) where T : Decodable {
        let publisher = PassthroughSubject<T, Error>()
        
        let listener = self.addSnapshotListener { documentSnapshot, error in
            self.getDocument(as: T.self) { result in
                do {
                    let item: T = try result.get()
                    publisher.send(item)
                } catch {
                    print("Error retrieving the value: \(error)")
                }
            }
        }
        
        return (publisher.eraseToAnyPublisher(), listener)
    }
}
