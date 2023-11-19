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
    
    // Here we have current user contacts.
    let contacts: [UserContact]
    
    var body: some View {
        List {
            if let currentUser = authViewModel.currentUser {
                ForEach(viewModel.users, id: \.id) { userWithContactData in
                    UserRowView(viewModel: viewModel, userWithContactData: userWithContactData, currentUser: currentUser)
                        .deleteDisabled(!userWithContactData.isContact)
                    
                    if userWithContactData == viewModel.users.last && !viewModel.allUsersFetched {
                        ProgressView().onAppear() {
                            Task {
                                do {
                                    try await viewModel.fetchUsers()
                                } catch {
                                    print("DEBUG:: Error fetching users", error.localizedDescription)
                                }
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    print("Going to delete item", indexSet.first!)
                    if let index = indexSet.first, let contactLink = viewModel.users[index].contactLink {
                        Task {
                            do {
                                try await viewModel.deleteContact(id: contactLink.id)
                                dismiss()
                            } catch {
                                print("DEBUG :: Error deleting contact", viewModel.users[indexSet.first!].contactLink!.id)
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
