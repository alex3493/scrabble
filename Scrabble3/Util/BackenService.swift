//
//  BackenService.swift
//  Scrabble3
//
//  Created by Alex on 29/10/23.
//

import Foundation
import Combine

protocol ValidationResponse: Codable {
    var isValid: Bool { get }
    var word: String { get }
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
    
    var word: String {
        return name
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
    
    var word: String {
        // TODO: make it better!!!
        return def[0].term
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

enum NetworkError: Error {
    case invalidURL
    case responseError(errorCode: Int?)
    case unknown
}

final class Api {
    
    static let shared = Api()
    private init() { }
    
    var cancellables = Set<AnyCancellable>()

    @MainActor
    func validateWord(word: String, lang: GameLanguage) async -> ValidationResponse? {
        var response: ValidationResponse?
        
        switch lang {
        case .ru:
            response = await ApiRussian.validateWord(word: word)
            // response = LocalDictServiceRussian.validateWord(word: word)
            break
        case .en:
            response = await ApiEnglish.validateWord(word: word)
            // response = LocalDictServiceEnglish.validateWord(word: word)
            break
        case .es:
            response = await ApiSpanish.validateWord(word: word)
            // response = LocalDictServiceSpanish.validateWord(word: word)
            break
        }
        
        //        if let response {
        //            print("DEBUG :: Word definition response", response.wordDefinition as Any)
        //        }
        
        return response
    }
    
    private func prepareURL(word: String, lang: GameLanguage) -> URL? {
        guard var url = Constants.Api.Validation.getUrl(lang: lang) else {
            return nil
        }
        
        switch lang {
        case .en:
            url.append(path: word.lowercased())
            url.appendPathExtension("json")
        case .ru:
            let query = URLQueryItem(name: "word", value: word)
            url.append(queryItems: [query])
        case .es:
            let query = URLQueryItem(name: "text", value: word)
            let keyQuery = URLQueryItem(name: "key", value: Constants.Api.Validation.dictKeyYandex)
            let langQuery = URLQueryItem(name: "lang", value: "es-en")
            url.append(queryItems: [query, keyQuery, langQuery])
        }
        
        return url
    }
    
    func validateWordsDataTaskPublisher<T: ValidationResponse>(as type: T.Type, words: [String], lang: GameLanguage, cache: [String: ValidationResponse]) -> AnyPublisher<[ValidationResponse], Error> {
        
        cancellables = []
        
        if words.isEmpty {
            // If there are no words in move there is nothing to validate.
            return CurrentValueSubject<[ValidationResponse], Error>([])
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        let publishers = words.compactMap {
            validateWordDataTaskPublisher(as: T.self, word: $0, lang: lang, cache: cache)
        }
        
        let publisher = PassthroughSubject<[ValidationResponse], Error>()
        
        var responses: [ValidationResponse] = []
        
        for pub in publishers {
            pub.sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let errorCode):
                    print("Error \(errorCode)")
                    publisher.send(completion: .failure(errorCode))
                case .finished:
                    break
                }
            }) { value in
                responses.append(value)
                
                if responses.count == words.count {
                    publisher.send(responses)
                }
            }
            .store(in: &cancellables)
        }
        
        return publisher.eraseToAnyPublisher()
    }
    
    func validateWordDataTaskPublisher<T: ValidationResponse>(as type: T.Type, word: String, lang: GameLanguage, cache: [String: ValidationResponse]) -> AnyPublisher<T, Error>? {
        
        var publisher: AnyPublisher<T, Error>?
        
        if let cached = cache[word] {
            publisher = CurrentValueSubject<T, Error>(cached as! T)
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        } else {
            guard let url = prepareURL(word: word, lang: lang) else { return nil }
            
            publisher = URLSession.shared.dataTaskPublisher(for: url)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                        throw NetworkError.responseError(errorCode: (response as? HTTPURLResponse)?.statusCode)
                    }
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        return publisher?.eraseToAnyPublisher()
    }
    
}
