//
//  ChangePasswordView.swift
//  Scrabble3
//
//  Created by Alex on 23/10/23.
//

import SwiftUI

struct ChangePasswordView: View {
    
    @State var password: String = ""
    @State var newPassword: String = ""
    
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    let errorStore = ErrorStore.shared
    
    var body: some View {
        VStack {
            Image(systemName: "swift")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .padding(.vertical, 32)
                .foregroundStyle(.cyan)
            VStack(spacing: 12) {
                TextInputView(text: $password, title: "Password", placeholder: "name@example.com", isSecureField: true)
                TextInputView(text: $newPassword, title: "New Password", placeholder: "Enter your password...", isSecureField: true)
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            ActionButton(label: "CHANGE PASSWORD", action: {
                if (await viewModel.updatePassword(newPassword: newPassword, currentPassword: password)) {
                    // TODO: show success alert here.
                    viewModel.signOut()
                } else {
                    print("DEBUG :: Error updating password")
                    errorStore.showLoginAlertView(withMessage: "Password could not be updated")
                }
            }, buttonSystemImage: "lock.fill", backGroundColor: Color(.systemBlue), maxWidth: true)
            
            Spacer()
        }
    }
}

#Preview {
    ChangePasswordView()
        .environmentObject(AuthWithEmailViewModel())
}
