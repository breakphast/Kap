//
//  Login.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct Login: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = "remy@loch.io"
    @State private var password = "remyrat"
    @State private var username = ""
    @State private var fullName = ""
    
    @State private var login = true
    @State private var loginFailed = false
    @Binding var loggedIn: Bool
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            
            HStack(spacing: 8) {
                Button("Login") {
                    withAnimation {
                        login.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(!login ? Color("oW") : Color("onyxLightish1"))
                .bold()
                
                Button("Register") {
                    withAnimation {
                        login.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(login ? Color("oW") : Color("onyxLightish1"))
                .bold()
            }
            
            if login {
                loginView
            } else {
                registerView
            }
        }
    }
    
    var loginView: some View {
        VStack {
            if loginFailed {
                Text("Login failed. Please try again.")
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(Color("oW"))
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                TextField("Email", text: $email)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                SecureField("Password", text: $password)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            
            Button {
                authViewModel.login(withEmail: email.lowercased(), password: password.lowercased()) { userID in
                    if let validUserID = userID {
//                        self.homeViewModel.activeUserID = validUserID
                        loggedIn.toggle()
                        loginFailed = false
                    } else {
                        print("Login failed")
                        loginFailed = true
                    }
                }
            } label: {
                Text("Login")
                    .font(.title.bold())
                    .foregroundStyle(Color("oW"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color("lion"))
                    .cornerRadius(8)
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal)
    }
    var registerView: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                TextField("Email", text: $email)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                SecureField("Password", text: $password)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                TextField("Username", text: $username)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                TextField("Full name", text: $fullName)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            
            Button("Register") {
                AuthViewModel().register(withEmail: email, password: password, username: username, fullName: fullName)
                login = true
//                AuthViewModel().login(withEmail: email, password: password) { userID in
//                    homeViewModel.activeUserID = userID ?? ""
//                }
//                loggedIn.toggle()
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(Color("lion"))
            .bold()
            .frame(width: 200)
            .tint(Color("oW"))
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }

}
