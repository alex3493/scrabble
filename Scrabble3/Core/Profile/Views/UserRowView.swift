//
//  UserRowView.swift
//  Scrabble3
//
//  Created by Alex on 16/11/23.
//

import SwiftUI

struct UserRowView: View {
    
    let viewModel: UserListViewModel
    let userWithContactData: UserWithContactData
    
    let currentUser: DBUser
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(userWithContactData.name)")
                    .fontWeight(.semibold)
                Text("\(userWithContactData.email)")
                    .font(.footnote)
            }
            
            Spacer()
            
            if !userWithContactData.isContact && userWithContactData.id != currentUser.userId {
                ActionButton(label: "Add contact", action: {
                    do {
                        try await viewModel.addContactRequest(targetUser: userWithContactData.user)
                        // We have to return to contact list view here.
                        dismiss()
                    } catch {
                        print("DEBUG :: Error adding user contact for user ", userWithContactData.user.email!)
                    }
                }, buttonSystemImage: "person.crop.circle.badge.plus", backGroundColor: .green, maxWidth: false)
            }
            
            if userWithContactData.isContact {
                if userWithContactData.isContactConfirmed {
                    Image(systemName: "heart.circle")
                } else if userWithContactData.isIncomingContact {
                    ActionButton(label: "Confirm", action: {
                        do {
                            try await viewModel.acceptContact(id: userWithContactData.contactLink!.id)
                            // We have to return to contact list view here.
                            dismiss()
                        } catch {
                            print("DEBUG :: Error confirming user contact for user ", userWithContactData.user.email!)
                        }
                    }, buttonSystemImage: "person.crop.circle.badge.plus", backGroundColor: .green, maxWidth: false)
                } else {
                    Image(systemName: "questionmark.circle")
                }
            }
            
        }
    }
}

struct UserRowView_Previews: PreviewProvider {
    static var previews: some View {
        let user = DBUser(userId: "fake_id", email: "fake@example.com", dateCreated: Date(), name: "Test user")
        UserRowView(viewModel: UserListViewModel(), userWithContactData: UserWithContactData(user: user, contactLink: nil, isIncomingContact: false), currentUser: user)
    }
}
