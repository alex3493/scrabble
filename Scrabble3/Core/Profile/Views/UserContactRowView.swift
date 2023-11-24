//
//  UserContactRowView.swift
//  Scrabble3
//
//  Created by Alex on 20/11/23.
//

import SwiftUI

struct UserContactRowView: View {
    
    let userContact: UserContact
    let viewModel: UserContactsViewModel
    let currentUser: DBUser?
    
    let errorStore = ErrorStore.shared
    
    var body: some View {
        if let currentUser = currentUser {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(userContact.displayContact(currentUserId: currentUser.userId).name!)")
                        .fontWeight(.semibold)
                    Text("\(userContact.displayContact(currentUserId: currentUser.userId).email!)")
                        .font(.footnote)
                }
                
                Spacer()
                
                if userContact.contactConfirmed {
                    Image(systemName: "heart.circle")
                } else if userContact.isIncomingContact(currentUserId: currentUser.userId) {
                    ActionButton(label: "Confirm", action: {
                        do {
                            try await viewModel.acceptContact(id: userContact.contactLink.id)
                        } catch {
                            print("DEBUG :: Error confirming user contact for user ", userContact.contactLink.id)
                            errorStore.showContactSetupAlertView(withMessage: error.localizedDescription)
                        }
                    }, buttonSystemImage: "person.crop.circle.badge.plus", backGroundColor: .green, maxWidth: false)
                } else {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
    }
}

struct UserContactRowView_Previews: PreviewProvider {
    static var previews: some View {
        let user = DBUser(userId: "fake_id", email: "fake@example.com", dateCreated: Date(), name: "Test user")
        UserContactRowView(userContact: UserContact(contactLink: UsersLinkModel(initiatorUserId: user.userId, counterpartUserId: user.userId, contactConfirmed: false), initiatorUser: user, counterpartUser: user), viewModel: UserContactsViewModel(), currentUser: user)
    }
}
