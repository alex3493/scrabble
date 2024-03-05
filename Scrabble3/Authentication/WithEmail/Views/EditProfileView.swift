//
//  EditProfileView.swift
//  Scrabble3
//
//  Created by Alex on 4/3/24.
//

import SwiftUI

struct EditProfileView: View {
    
    @State var name: String = ""
    
    let errorStore = ErrorStore.shared
    
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            TextInputView(text: $name, title: "Name", placeholder: "Enter your name...", isSecureField: false)
            
            Spacer()
            
            Button {
                Task {
                    do {
                        try await viewModel.updateUserProfile(name: name)
                        try await viewModel.fetchUser()
                        dismiss()
                    } catch {
                        print("DEBUG :: Error updating user profile: \(error.localizedDescription)")
                        errorStore.showProfileUpdateAlertView(withMessage: error.localizedDescription)
                    }
                }
            } label: {
                HStack {
                    Text("SAVE")
                        .fontWeight(.semibold)
                    Image(systemName: "checkmark")
                }
                .foregroundColor(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color(.systemBlue))
            .cornerRadius(10)
            .padding(.top, 24)
            .disabled(submitDisabled)
            .opacity(submitDisabled ? 0.5 : 1.0)
        }
        .padding()
        .onAppear {
            name = viewModel.currentUser?.name ?? ""
        }
    }
    
    var submitDisabled: Bool {
        name.isEmpty
    }
}

#Preview {
    EditProfileView()
}
