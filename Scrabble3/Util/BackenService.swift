//
//  BackenService.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation

protocol ValidationResponse {
    var isValid: Bool { get }
}

//MARK : word definitions.
struct WordDefinitionRussian: Codable {
    let term: String
    let short: String
    let dic: String
    let ident: Int
    let imageURL: String?
}

struct WordDefinitionEnglish: Codable {
    let word: String
    let definition: String
    let inflection: String
    let wordSize: Int
    let wordScore: Int
}

struct WordDefinitionSpanish: Codable {
    let text: String
    let pos: String
    let gen: String
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
}

struct ValidationResponseEnglish: Codable, ValidationResponse {
    let success: Bool
    let data: [WordDefinitionEnglish]
    
    var isValid: Bool {
        return success
    }
}

struct ValidationResponseSpanish: Codable, ValidationResponse {
    let def: [WordDefinitionSpanish]
    
    var isValid: Bool {
        return !def.isEmpty
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
        
        guard var url = URL(string: "https://shop.hasbro.com/api/scrabble/dictionary/") else {
            return nil
        }
        url.append(path: word)
        
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
        let langQuery = URLQueryItem(name: "lang", value: "es-ru")
        
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
//        default:
//            response = nil
        }
        
        // print("DEBUG :: Word validation response", response as Any)
        
        return response
    }
}
