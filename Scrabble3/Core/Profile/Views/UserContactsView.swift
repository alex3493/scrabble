//
//  UserContactsView.swift
//  Scrabble3
//
//  Created by Alex on 16/11/23.
//

import SwiftUI

struct UserContactsView: View {
    
    @ObservedObject var viewModel = UserContactsViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    @ObservedObject var userListViewModel = UserListViewModel()
    
    var body: some View {
        VStack {
            List {
                ForEach(viewModel.contactUsers, id: \.id) { contactUser in
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
                            }
                        }
                    }
                }
            }
        }
        .onAppear() {
            viewModel.currentUser = authViewModel.currentUser
        }
        .task {
            viewModel.addListenerForContacts()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink {
                    UserListView(viewModel: userListViewModel, contacts: viewModel.contactUsers)
                        .navigationTitle("Добавить контакт")
                } label: {
                    HStack {
                        Text("Добавить")
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
    UserContactsView()
}
