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

//struct WordDefinitionEnglish: Codable, WordDefinition {
//    var term: String {
//        return word
//    }
//
//    var imageURL: String? {
//        return nil
//    }
//
//    let word: String
//    let definition: String
//    let inflection: String
//    let wordSize: Int
//    let wordScore: Int
//}

//struct WordDefinitionEnglish: Codable, WordDefinition {
//    var term: String {
//        return name
//    }
//
//    var imageURL: String? {
//        return nil
//    }
//
//    let name: String
//    let definition: String
//}

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

//struct ValidationResponseEnglish: Codable, ValidationResponse {
//    let success: Bool
//    let data: [WordDefinitionEnglish]
//
//    var isValid: Bool {
//        return success
//    }
//
//    var definition: WordDefinition? {
//        guard !data.isEmpty else { return nil }
//        return WordInfo(term: data[0].term, definition: data[0].definition, imageURL: data[0].imageURL)
//    }
//}

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
        guard var url = URL(string: "https://erugame.ru/dictionary/backend.php?mode=new") else {
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
        
        guard var url = URL(string: "https://s3-us-west-2.amazonaws.com/words.alexmeub.com/nwl20/") else {
            return nil
        }
        
        //        guard var url = URL(string: "https://shop.hasbro.com/api/scrabble/dictionary/") else {
        //            return nil
        //        }
        
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
        let keyQuery = URLQueryItem(name: "key", value: "dict.1.1.20231125T101354Z.02e231dd0878d9ec.4ea53be52aea0fd9b6ecb0b965d7582cfd872539")
        let langQuery = URLQueryItem(name: "lang", value: "es-en")
        
        guard var url = URL(string: "https://dictionary.yandex.net/api/v1/dicservice.json/lookup") else {
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
            response = await ApiRussian.validateWord(word: word)
            break
        case .en:
            response = await ApiEnglish.validateWord(word: word)
            break
        case .es:
            response = await ApiSpanish.validateWord(word: word)
            break
        }
        
        if let response {
            print("DEBUG :: Validation response", response.wordDefinition as Any)
        }
        
        return response
    }
}
