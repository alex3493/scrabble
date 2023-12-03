//
//  BackenService.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

protocol ValidationResponse {
    var isValid: Bool { get }
    var wordDefinition: WordDefinition? { get }
}

//MARK : word definitions.
protocol WordDefinition: Codable {
    var term: String { get }
    var definition: String { get }
    var imageURL: String? { get }
}

struct WordDefinitionRussian: Codable, WordDefinition {
    var definition: String {
        return short
    }
    
    let term: String
    let short: String
    let dic: String
    let ident: Int
    let imageURL: String?
}

struct WordDefinitionSpanish: Codable, WordDefinition {
    var term: String {
        return text
    }
    
    var definition: String {
        guard !tr.isEmpty, !tr[0].mean.isEmpty else { return "" }
        // We just return the first meaning in response array.
        return tr[0].mean[0].text
    }
    
    var imageURL: String? {
        return nil
    }
    
    struct Translation: Codable {
        let mean: [Mean]
    }
    
    struct Mean: Codable {
        let text: String
    }
    
    let text: String
    let pos: String
    let gen: String
    let tr: [Translation]
}

//MARK : validation responses.
struct ValidationResponseRussian: Codable, ValidationResponse {
    let result: String
    let word: String
    let definitions: [WordDefinitionRussian]?
    let usage_rate: Int?
    let imageURL: String?
    
    var isValid: Bool {
        return result == "yes"
    }
    
    var wordDefinition: WordDefinition? {
        guard let definitions, !definitions.isEmpty else { return nil }
        return WordInfo(term: word, definition: definitions[0].short, imageURL: imageURL)
    }
}

struct ValidationResponseEnglish: Codable, ValidationResponse {
    let name: String
    let definition: String
    
    var isValid: Bool {
        return true
    }
    
    var wordDefinition: WordDefinition? {
        return WordInfo(term: name, definition: definition, imageURL: nil)
    }
}

struct ValidationResponseSpanish: Codable, ValidationResponse {
    let def: [WordDefinitionSpanish]
    
    var isValid: Bool {
        return !def.isEmpty
    }
    
    var wordDefinition: WordDefinition? {
        guard !def.isEmpty else { return nil }
        return WordInfo(term: def[0].term, definition: def[0].definition, imageURL: def[0].imageURL)
    }
}

//MARK : API requests.
struct ApiRussian {
    @MainActor
    static func validateWord(word: String) async -> ValidationResponse? {
        let query = URLQueryItem(name: "word", value: word)
        guard var url = Constants.Api.Validation.getUrl(lang: .ru) else {
            return nil
        }
        url.append(queryItems: [query])
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try? JSONDecoder().decode(ValidationResponseRussian.self, from: data)
        } catch {
            // TODO: should re-throw?
            return nil
        }
    }
}

struct ApiEnglish {
    @MainActor
    static func validateWord(word: String) async -> ValidationResponse? {
        
        guard var url = Constants.Api.Validation.getUrl(lang: .en) else {
            return nil
        }
        
        url.append(path: word.lowercased())
        url.appendPathExtension("json")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try? JSONDecoder().decode(ValidationResponseEnglish.self, from: data)
        } catch {
            // TODO: should re-throw?
            return nil
        }
    }
}

struct ApiSpanish {
    @MainActor
    static func validateWord(word: String) async -> ValidationResponse? {
        let query = URLQueryItem(name: "text", value: word)
        let keyQuery = URLQueryItem(name: "key", value: Constants.Api.Validation.dictKeyYandex)
        let langQuery = URLQueryItem(name: "lang", value: "es-en")
        
        guard var url = Constants.Api.Validation.getUrl(lang: .es) else {
            return nil
        }
        url.append(queryItems: [query, keyQuery, langQuery])
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return try? JSONDecoder().decode(ValidationResponseSpanish.self, from: data)
        } catch {
            // TODO: should re-throw?
            return nil
        }
    }
}

struct Api {
    @MainActor
    static func validateWord(word: String, lang: GameLanguage) async -> ValidationResponse? {
        var response: ValidationResponse?
        
        switch lang {
        case .ru:
            // response = await ApiRussian.validateWord(word: word)
            response = LocalDictServiceRussian.validateWord(word: word)
            break
        case .en:
            // response = await ApiEnglish.validateWord(word: word)
            response = LocalDictServiceEnglish.validateWord(word: word)
            break
        case .es:
            // response = await ApiSpanish.validateWord(word: word)
            response = LocalDictServiceSpanish.validateWord(word: word)
            break
        }
        
        if let response {
            print("DEBUG :: Word definition response", response.wordDefinition as Any)
        }
        
        return response
    }
}
