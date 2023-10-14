//
//  ProfileView.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    var body: some View {
        List {
            if let user = viewModel.currentUser {
                if let name = user.name {
                    Section {
                        HStack {
                            Text(user.initials)
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 72, height: 72)
                                .background(Color(.systemGray3))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .fontWeight(.semibold)
                                    .font(.subheadline)
                                    .padding(.top, 4)
                                Text(user.email!)
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section("General") {
                    HStack {
                        SettingsRowView(imageName: "gear", title: "Version", tintColor: Color(.systemGray))
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Account") {
                    Button {
                        viewModel.signOut()
                    } label: {
                        SettingsRowView(imageName: "arrow.left.circle.fill", title: "Sign Out", tintColor: Color(.red))
                    }
                    
                    Button {
                        viewModel.deleteAccount()
                    } label: {
                        SettingsRowView(imageName: "xmark.circle.fill", title: "Delete Account", tintColor: Color(.red))
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthWithEmailViewModel())
}
