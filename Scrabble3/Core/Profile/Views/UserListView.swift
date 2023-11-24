//
//  UserListView.swift
//  Scrabble3
//
//  Created by Alex on 15/11/23.
//

import SwiftUI

struct UserListView: View {
    
    @ObservedObject var viewModel: UserListViewModel
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @Environment(\.dismiss) var dismiss
    
    let errorStore = ErrorStore.shared
    
    // Here we have current user contacts.
    let contacts: [UserContact]
    
    var body: some View {
        List {
            ForEach(viewModel.users, id: \.id.self) { user in
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(user.name!)")
                            .fontWeight(.semibold)
                        Text("\(user.email!)")
                            .font(.footnote)
                    }
                    
                    Spacer()
                    
                    ActionButton(label: "Add contact", action: {
                        do {
                            try await viewModel.addContactRequest(targetUser: user)
                            // We have to return to contact list view here.
                            dismiss()
                        } catch {
                            print("DEBUG :: Error adding user contact for user ", user.email!)
                            errorStore.showContactSetupAlertView(withMessage: error.localizedDescription)
                        }
                    }, buttonSystemImage: "person.crop.circle.badge.plus", backGroundColor: .green, maxWidth: false)
                }
                
                if user == viewModel.users.last && !viewModel.allUsersFetched {
                    ProgressView().onAppear() {
                        Task {
                            do {
                                try await viewModel.fetchUsers()
                            } catch {
                                print("DEBUG:: Error fetching users", error.localizedDescription)
                                errorStore.showContactSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
        .task {
            do {
                try await viewModel.fetchUsers(reload: true)
            } catch {
                print("DEBUG :: Error fetching users", error.localizedDescription)
                errorStore.showContactSetupAlertView(withMessage: error.localizedDescription)
            }
        }
        .onAppear() {
            print("User list view appeared")
            viewModel.currentUser = authViewModel.currentUser
            viewModel.contacts = contacts
        }
        
    }
}

#Preview {
    UserListView(viewModel: UserListViewModel(), contacts: [])
}
