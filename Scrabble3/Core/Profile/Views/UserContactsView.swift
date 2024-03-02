//
//  UserContactsView.swift
//  Scrabble3
//
//  Created by Alex on 16/11/23.
//

import SwiftUI

struct UserContactsView: View {
    @StateObject private var viewModel: UserContactsViewModel
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @StateObject var userListViewModel = UserListViewModel()
    
    let errorStore = ErrorStore.shared
    
    init(viewModel: UserContactsViewModel) {
        print("UserContactsView INIT")
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.contactUsers, id: \.id.self) { contactUser in
                    UserContactRowView(userContact: contactUser, viewModel: viewModel, currentUser: authViewModel.currentUser)
                }
                .onDelete { indexSet in
                    print("Going to delete item", indexSet.first!)
                    if let index = indexSet.first {
                        let contactLink = viewModel.contactUsers[index].contactLink
                        Task {
                            do {
                                try await viewModel.deleteContact(id: contactLink.id)
                            } catch {
                                print("DEBUG :: Error deleting contact", viewModel.contactUsers[indexSet.first!].contactLink.id)
                                errorStore.showContactSetupAlertView(withMessage: error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
        .onAppear() {
            viewModel.currentUser = authViewModel.currentUser
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    UserListView(viewModel: userListViewModel, contacts: viewModel.contactUsers)
                        .navigationTitle("Добавить контакт")
                } label: {
                    HStack {
                        Text("Add contact")
                        Spacer()
                        Image(systemName: "person.badge.plus")
                            .font(.headline)
                    }
                }
            }
        }
    }
}

#Preview {
    UserContactsView(viewModel: UserContactsViewModel())
}
