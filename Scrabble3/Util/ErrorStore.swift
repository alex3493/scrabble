//
//  ErrorStore.swift
//  Scrabble3
//
//  Created by Alex on 14/10/23.
//

import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case loginError(message: String?)
    
    case registrationError(message: String?)
    
    case gameSetupError(message: String?)
    
    case moveValidationError(errorType: ValidationError)
    
    var errorDescription: String? {
        switch self {
        case .loginError:
            return "Failed logging in account"
        case .registrationError:
            return "Failed registering new account"
        case .gameSetupError:
            return "Error setting up game"
        case .moveValidationError:
            return "ОШИБКА"
        }
    }
    
    var failureReason: String? {
        switch self {
            
        case .loginError(let message):
            return message ?? "Entered email or password were incorrect"
        case .registrationError(let message):
            return message ?? "Email address is already in use"
        case .gameSetupError(let message):
            return message ?? "Error trying to create, join, leave, remove or start game"
        case .moveValidationError(let errorType):
            switch errorType {
                
            case .invalidLetterTilePosition(cell: let cell):
                return "Буква расположена неправильно: \(cell)"
            case .hangingWords(words: let words):
                let words = words.joined(separator: ", ")
                return "Слова расположены неправильно: \(words)"
            case .invalidWords(words: let words):
                let words = words.joined(separator: ", ")
                return "Слова не найдены в словаре: \(words)"
            case .repeatedWords(words: let words):
                let words = words.joined(separator: ", ")
                return "Слова уже использованы: \(words)"
            }
        }
        
    }
    
}

final class ErrorStore: ObservableObject {
    static let shared = ErrorStore()
    
    private init() { }
    
    @Published private(set) var activeError: AppError?
    
    var isPresentingAlert: Binding<Bool> {
        return Binding<Bool>(get: {
            return self.activeError != nil
        }, set: { newValue in
            guard !newValue else { return }
            self.activeError = nil
        })
    }
    
    func showLoginAlertView(withMessage message: String?) {
        activeError = AppError.loginError(message: message)
    }
    
    func showRegistrationAlertView(withMessage message: String?) {
        activeError = AppError.registrationError(message: message)
    }
    
    func showGameSetupAlertView(withMessage message: String?) {
        activeError = AppError.gameSetupError(message: message)
    }
    
    func showMoveValidationErrorAlert(errorType: ValidationError) {
        activeError = AppError.moveValidationError(errorType: errorType)
    }
    
}


struct ErrorAlert: ViewModifier {
    @ObservedObject var errorStore = ErrorStore.shared
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: errorStore.isPresentingAlert) {
                Alert(
                    title: Text((errorStore.activeError?.errorDescription)!),
                    message: Text((errorStore.activeError?.failureReason)!)
                )
            }
    }
    
    
}
