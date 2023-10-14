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
    
    var errorDescription: String? {
        switch self {
        case .loginError:
            return "Failed logging in account"
        case .registrationError:
            return"Failed registering new account"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .loginError(let message):
            return message ?? "Entered email or password were incorrect"
        case .registrationError(let message):
            return message ?? "Email address is already in use"
        }
    }
    
    //    var recoverySuggestion: String? {
    //        switch self {
    //        case .loginError:
    //            return "Please try again with different credentials"
    //        case .registrationError:
    //            return "Please try again with different email"
    //        }
    //    }
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
