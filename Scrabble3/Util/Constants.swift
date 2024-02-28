//
//  Constants.swift
//  Scrabble3
//
//  Created by Alex on 3/12/23.
//

import Foundation

struct Constants {
    
    struct Game {
        struct Board {
            static let rows = 15
            static let cols = 15
        }
        struct Rack {
            static let size = 8
        }
        
        static let bonusFullRackMove = 15
    }
    
    struct Api {
        struct Validation {
            static func getUrl(lang: GameLanguage) -> URL? {
                switch lang {
                case .en:
                    return URL(string: "https://s3-us-west-2.amazonaws.com/words.alexmeub.com/nwl20/")
                case .ru:
                    return URL(string: "https://erugame.ru/dictionary/backend.php?mode=new")
                case .es:
                    return URL(string: "https://dictionary.yandex.net/api/v1/dicservice.json/lookup")
                }
            }
            static let dictKeyYandex = "dict.1.1.20231125T101354Z.02e231dd0878d9ec.4ea53be52aea0fd9b6ecb0b965d7582cfd872539"
        }
    }
}
