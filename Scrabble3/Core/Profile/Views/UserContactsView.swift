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
            ForEach(viewModel.contactUsers, id: \.id) { contactUser in
                if contactUser.isUserInitiator(user: authViewModel.currentUser) {
                    HStack {
                        Text("Counterpart: \(contactUser.counterpartUser.name!)")
                        ActionButton(label: "Delete", action: {
                            do {
                                try await viewModel.deleteContact(id: contactUser.id)
                            } catch {
                                print("DEBUG :: Error deleting contact", contactUser)
                            }
                        }, buttonSystemImage: "trash", backGroundColor: .red, maxWidth: false)
                    }
                } else {
                    HStack {
                        Text("Initiator: \(contactUser.initiatorUser.name!)")
                        if contactUser.canAcceptContact {
                            ActionButton(label: "Accept", action: {
                                do {
                                    try await viewModel.acceptContact(id: contactUser.id)
                                } catch {
                                    print("DEBUG :: Error accepting contact", contactUser)
                                }
                            }, buttonSystemImage: "heart", backGroundColor: .green, maxWidth: false)
                        }
                        
                        ActionButton(label: "Delete", action: {
                            do {
                                try await viewModel.deleteContact(id: contactUser.id)
                            } catch {
                                print("DEBUG :: Error deleting contact", contactUser)
                            }
                        }, buttonSystemImage: "trash", backGroundColor: .red, maxWidth: false)
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
                        .navigationTitle("Все игроки")
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
