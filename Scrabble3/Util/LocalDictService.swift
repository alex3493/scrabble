//
//  LocalDictService.swift
//  Scrabble3
//
//  Created by Alex on 27/11/23.
//

import Foundation

class LocalDictService {
   
    static let languageFiles = [
        "ru": "russian",
        "en": "english",
        "es": "espanol",
        "ca": "catalan"
    ]
    
    static var lang: GameLanguage? = nil
    static var dictionary: String = ""
    
    static func loadDictionary(lang: GameLanguage) {

        let url = Bundle.main.url(forResource: languageFiles[lang.rawValue], withExtension: "dic", subdirectory: "Dic")
        do {
            if let url = url, try url.checkResourceIsReachable() {
                print("file exist")
                if let fileContents = try? String(contentsOf: url) {
                    print("File loaded")
                    
                    self.dictionary = fileContents
                    self.lang = lang
                }
            } else {
                throw URLError(.fileDoesNotExist)
            }
        } catch {
            print("DEBUG :: Error loading \(lang) dictionary file", error.localizedDescription)
        }
    }
    
    static func validateWord(word: String, lang: GameLanguage) -> ValidationResponse {
        
        // If dictionary was not loaded yet or we have changed the language
        // make sure that we init the dictionary.
        if dictionary.isEmpty || lang != self.lang {
            loadDictionary(lang: lang)
        }
        
        let result = self.checkWord(word: word)
        
        switch lang {
        case .ru:
            return ValidationResponseRussian(result: result ? "yes" : "no", word: word, definitions: nil, usage_rate: nil, imageURL: nil)
        case .en:
            return ValidationResponseEnglish(name: word, definition: result ? "" : nil)
        case .es:
            return ValidationResponseSpanish(def: result ? [WordDefinitionSpanish(text: word, pos: "", gen: nil, tr: [])] : [])
        }
        
    }
    
    class func checkWord(word: String) -> Bool {
        guard !self.dictionary.isEmpty else { return false }
        
        let pattern = "\\s\(word)\\s"
        do {
            let regex = try Regex(pattern)
            return self.dictionary.contains(regex)
        } catch {
            print("DEBUG :: Error setting up search", error.localizedDescription)
            return false
        }
    }
}

class LocalDictServiceRussian: LocalDictService {
    static func validateWord(word: String) -> ValidationResponse {
        return super.validateWord(word: word, lang: .ru)
    }
}

class LocalDictServiceEnglish: LocalDictService {
    static func validateWord(word: String) -> ValidationResponse {
        return super.validateWord(word: word, lang: .en)
    }
    
    // Currently used english dictionary requires custom regex.
    override static func checkWord(word: String) -> Bool {
        guard !self.dictionary.isEmpty else { return false }
        
        let pattern = "\\s\(word)="
        do {
            let regex = try Regex(pattern)
            return self.dictionary.contains(regex)
        } catch {
            print("DEBUG :: Error setting up search", error.localizedDescription)
            return false
        }
    }
}

class LocalDictServiceSpanish: LocalDictService {
    static func validateWord(word: String) -> ValidationResponse {
        
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
        
        return super.validateWord(word: replaced, lang: .es)
    }
}

//class LocalDictServiceCatalan: LocalDictService {
//    func validateWord(word: String) -> ValidationResponse {
//        
//        // We have to replace special tiles with numbers as it is required by dictionary.
//        /*
//         | [Replace]
//         | 1=L·L
//         | 2=NY
//         | 3=QU
//         */
//        let replaced = word
//            .replacingOccurrences(of: "L·L", with: "1")
//            .replacingOccurrences(of: "NY", with: "2")
//            .replacingOccurrences(of: "QU", with: "3")
//        
//        return super.validateWord(word: replaced, lang: .ca)
//    }
//}
