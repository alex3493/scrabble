//
//  ProfileView.swift
//  Scrabble3
//
//  Created by Alex on 9/10/23.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AuthWithEmailViewModel
    
    // TODO: Explore @AppStorage wrapper.
    @AppStorage("PreferredLang") var preferredLang: GameLanguage = .ru
    
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
                    
                    Picker(selection: $preferredLang) {
                        Text("Russian").tag(GameLanguage.ru)
                        Text("English").tag(GameLanguage.en)
                        Text("Spanish").tag(GameLanguage.es)
                    } label: {
                        SettingsRowView(imageName: "character.book.closed", title: "Game Language", tintColor: Color(.systemGray))
                        
                    }
                }
                
                Section("Account") {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.circle")
                            .imageScale(.small)
                            .font(.title)
                            .foregroundColor(Color(.systemGray))
                        NavigationLink(destination: ChangePasswordView(), label: {
                            Text("Change Password")
                        })
                    }
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
        .onAppear() {
            preferredLang = GameLanguage(rawValue: UserDefaults.standard.string(forKey: "PreferredLang") ?? "ru") ?? GameLanguage.ru
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthWithEmailViewModel())
}
