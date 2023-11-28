//
//  LocalDictService.swift
//  Scrabble3
//
//  Created by Alex on 27/11/23.
//

import Foundation

struct LocalDictServiceResponse: ValidationResponse {
    var isValid: Bool
    
    var wordDefinition: WordDefinition? = nil
}

class LocalDictService {
    static func loadDictionary(lang: String) {

        let url = Bundle.main.url(forResource: lang, withExtension: "dic", subdirectory: "Dic")
        do {
            if let url = url, try url.checkResourceIsReachable() {
                print("file exist")
                if let fileContents = try? String(contentsOf: url) {
                    print("File loaded")
                    
                    LocalDictService.dictionary = fileContents
                }
            } else {
                throw URLError(.fileDoesNotExist)
            }
        } catch {
            print("DEBUG :: Error loading \(lang) dictionary file", error.localizedDescription)
        }
    }
    
    static var dictionary: String = ""
    
    static func validateWord(word: String, lang: String) -> LocalDictServiceResponse {
        
        if dictionary.isEmpty {
            loadDictionary(lang: lang)
        }
        
        let result = checkWord(word: word)
        
        return LocalDictServiceResponse(isValid: result)
    }
    
    private static func checkWord(word: String) -> Bool {
        guard !dictionary.isEmpty else { return false }
        
        let pattern = "\\s\(word)\\s"
        do {
            let regex = try Regex(pattern)
            return dictionary.contains(regex)
        } catch {
            print("DEBUG :: Error setting up search", error.localizedDescription)
            return false
        }
    }
}

class LocalDictServiceRussian: LocalDictService {
    static func validateWord(word: String) -> LocalDictServiceResponse {
        return super.validateWord(word: word, lang: "russian")
    }
}

class LocalDictServiceEnglish: LocalDictService {
    static func validateWord(word: String) -> LocalDictServiceResponse {
        return super.validateWord(word: word, lang: "english")
    }
}

class LocalDictServiceSpanish: LocalDictService {
    static func validateWord(word: String) -> LocalDictServiceResponse {
        
        // We have to replace special tiles with numbers as it is required by dictionary.
        /*
         | [Replace]
         | 1=CH
         | 2=LL
         | 3=RR
         */
        let replaced = word
            .replacingOccurrences(of: "CH", with: "1")
            .replacingOccurrences(of: "LL", with: "2")
            .replacingOccurrences(of: "RR", with: "3")
        
        return super.validateWord(word: replaced, lang: "espanol")
    }
}

class LocalDictServiceCatalan: LocalDictService {
    static func validateWord(word: String) -> LocalDictServiceResponse {
        
        // We have to replace special tiles with numbers as it is required by dictionary.
        /*
         | [Replace]
         | 1=L·L
         | 2=NY
         | 3=QU
         */
        let replaced = word
            .replacingOccurrences(of: "L·L", with: "1")
            .replacingOccurrences(of: "NY", with: "2")
            .replacingOccurrences(of: "QU", with: "3")
        
        return super.validateWord(word: replaced, lang: "catalan")
    }
}
