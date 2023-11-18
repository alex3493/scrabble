//
//  UserListView.swift
//  Scrabble3
//
//  Created by Alex on 15/11/23.
//

import SwiftUI

struct UserListView: View {
    
    @ObservedObject var viewModel = UserListViewModel()
    
    @EnvironmentObject var authViewModel: AuthWithEmailViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.users, id: \.userId) { user in
                UserRowView(viewModel: viewModel, user: user)
                
                if user == viewModel.users.last && viewModel.currentUser != nil && !viewModel.allUsersFetched {
                    ProgressView()
                        .onAppear() {
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
        }
        .task {
            do {
                try await viewModel.fetchUsers()
            } catch {
                print("DEBUG :: Error fetching users", error.localizedDescription)
            }
        }
        .onAppear() {
            viewModel.currentUser = authViewModel.currentUser
        }
    }
}

#Preview {
    UserListView()
}
