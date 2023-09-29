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
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    @AppStorage("email") private var emailAddy = ""
    @AppStorage("password") private var pass = ""

    @State private var email = UserDefaults.standard.string(forKey: "email")?.lowercased()
    @State private var password = UserDefaults.standard.string(forKey: "password")
    @State private var username = ""
    @State private var fullName = ""
    @State private var login = true
    @State private var loginFailed = false
    @State private var showLeagueList = false
    @State private var showLeagueIntro = false
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
                .foregroundStyle(!login ? Color("oW") : Color("onyx"))
                .bold()
                
                Button("Register") {
                    withAnimation {
                        login.toggle()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundStyle(login ? Color("oW") : Color("onyx"))
                .bold()
                .disabled(true)
            }
            
            if login {
                loginView
            } else {
                registerView
            }
        }
        .fullScreenCover(isPresented: $showLeagueList) {
            LeagueList(leagues: $homeViewModel.userLeagues, loggedIn: $loggedIn)
        }
        .fullScreenCover(isPresented: $showLeagueIntro) {
            LeagueIntro(loggedIn: $loggedIn)
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
                
                TextField("Email", text: $emailAddy)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                SecureField("Password", text: $pass)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            
            Button {
                authViewModel.login(withEmail: emailAddy.lowercased(), password: pass) { userID in
                    guard userID != nil else {
                        print("Login failed")
                        loginFailed = true
                        return
                    }
                    Task {
                        homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: userID!)
                        let fault = UserDefaults.standard.string(forKey: "defaultLeagueID")
                        guard fault == "" else {
                            homeViewModel.activeLeagueID = fault
                            leagueViewModel.activeLeague = homeViewModel.leagues.first(where: {$0.code == fault})
                            if let activeLeague = leagueViewModel.activeLeague {
                                leagueViewModel.points = activeLeague.points ?? [:]
                                let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == activeLeague.code })?.players
                                if let leaguePlayers = leaguePlayers {
                                    homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
                                }
                            }
                            await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, week: homeViewModel.currentWeek)
                            await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, week: 3)
                            loggedIn = true
                            return
                        }
                        
                        if homeViewModel.userLeagues.count > 0 {
                            showLeagueList.toggle()
                        } else {
                            showLeagueIntro.toggle()
                        }
                    }
                }
            } label: {
                Text("Login")
                    .font(.title2.bold())
                    .foregroundStyle(Color("oW"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color("lion"))
                    .cornerRadius(8)
            }
            .autocorrectionDisabled()
            .autocapitalization(.none)
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
                
                TextField("Email", text: $emailAddy)
                    .font(.title.bold().width(.condensed))
                    .foregroundStyle(Color("oW"))
                    .padding()
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .foregroundStyle(Color("lion"))
                    .frame(height: 50)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 2, y: 2)
                
                SecureField("Password", text: $pass)
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
                AuthViewModel().register(withEmail: emailAddy, password: pass, username: username, fullName: fullName)
                login = true
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
