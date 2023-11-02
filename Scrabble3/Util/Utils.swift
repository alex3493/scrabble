//
//  Utils.swift
//  Scrabble3
//
//  Created by Alex on 2/11/23.
//

import Foundation
import Firebase

struct Utils {
    static func formatTransactionTimestamp(_ timestamp: Timestamp?) -> String {
      if let timestamp = timestamp {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
         
        let date = timestamp.dateValue()
        dateFormatter.locale = Locale.current
        let formatted = dateFormatter.string(from: date)
        return formatted
      }
      return ""
    }
}
