//
//  UserRowView.swift
//  Scrabble3
//
//  Created by Alex on 16/11/23.
//

import SwiftUI

struct UserRowView: View {
    
    let viewModel: UserListViewModel
    let user: DBUser
    
    var body: some View {
        HStack {
            Text("\(user.name!)")
            
            ActionButton(label: "Add contact", action: {
                do {
                    try await viewModel.addContactRequest(targetUser: user)
                } catch {
                    print("DEBUG :: Error adding user contact for user ", user.email!)
                }
            }, buttonSystemImage: "person.crop.circle.badge.plus", backGroundColor: .green, maxWidth: false)
            
        }
    }
}

#Preview {
    UserRowView(viewModel: UserListViewModel(), user: DBUser(userId: "fake_id", email: "fake@email.com", dateCreated: Date(), name: "Test user"))
}
