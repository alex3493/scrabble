//
//  BackenService.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

struct WordDefinition: Codable {
    let term: String
    let short: String
    let dic: String
    let ident: Int
    let imageURL: String?
}

struct ValidationResponse: Codable {
    let result: String
    let word: String
    let definitions: [WordDefinition]?
    let usage_rate: Int?
    let imageURL: String?
}

struct Api {
    @MainActor
    static func validateWord(word: String) async -> ValidationResponse? {
        let query = URLQueryItem(name: "word", value: word)
        guard var url = URL(string: "https://erugame.ru/dictionary/backend.php?mode=new") else {
            return nil
        }
        url.append(queryItems: [query])
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try? JSONDecoder().decode(ValidationResponse.self, from: data)
        } catch {
            // TODO: should re-throw?
            return nil
        }
    }
}
