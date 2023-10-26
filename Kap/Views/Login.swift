//
//  Login.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI
import CoreData

struct Login: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    @AppStorage("email") private var emailAddy = ""
    @AppStorage("password") private var pass = ""
    @AppStorage("defaultleagueCode") private var defaultleagueCode = ""
    @State private var email = UserDefaults.standard.string(forKey: "email")?.lowercased()
    @State private var password = UserDefaults.standard.string(forKey: "password")
    @State private var username = ""
    @State private var fullName = ""
    @State private var login = true
    @State private var loginFailed = false
    @State private var showLeagueList = false
    @State private var showLeagueIntro = false
    @State var loggingIn = false
    @Binding var loggedIn: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
            entity: GameModel.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \GameModel.date, ascending: true)
            ]
        ) var allGameModels: FetchedResults<GameModel>
    
    @FetchRequest(
        entity: BetModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BetModel.timestamp, ascending: true)
        ]
    ) var allBetModels: FetchedResults<BetModel>
    
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
                    .textInputAutocapitalization(.never)
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
                DispatchQueue.main.async {
                    loggingIn = true
                    
                    authViewModel.login(withEmail: emailAddy.lowercased(), password: pass) { userID in
                        guard userID != nil else {
                            print("Login failed")
                            loginFailed = true
                            loggingIn.toggle()
                            return
                        }
                        Task {
                            if allGameModels.isEmpty {
                                print("No games. Adding now...")
                                do {
                                    try await homeViewModel.addInitialGames(in: viewContext)
                                    homeViewModel.allGameModels = self.allGameModels
                                    if let allGames = homeViewModel.allGameModels {
                                        do {
                                            try await Board().updateGameOdds(games: Array(allGames).filter({$0.week == homeViewModel.currentWeek}), in: viewContext)
                                            homeViewModel.allGameModels = self.allGameModels
                                            print("Done adding games.")
                                        } catch {
                                            
                                        }
                                    }
                                } catch {
                                    
                                }
                            }
                            homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: userID!)
                            let defaultCode = UserDefaults.standard.string(forKey: "defaultleagueCode")
                            guard defaultCode == "" else {
                                if defaultCode == "5555" {
                                    leaderboardViewModel.leagueType = .season
                                } else {
                                    leaderboardViewModel.leagueType = .weekly
                                }
                                homeViewModel.activeleagueCode = defaultCode
                                leagueViewModel.activeLeague = homeViewModel.leagues.first(where: {$0.code == defaultCode})
                                
                                if let activeLeague = leagueViewModel.activeLeague {
                                    homeViewModel.allGameModels = self.allGameModels
                                    homeViewModel.allBetModels = self.allBetModels

                                    await homeViewModel.fetchEssentials(updateGames: false, updateScores: false, league: activeLeague, in: viewContext)
                                    homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                                    homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                                    if let last = Array(allBetModels).last {
                                        if let timestamp = last.timestamp {
                                            homeViewModel.counter?.timestamp = timestamp
                                            print("Current timestampppp:", timestamp)
                                            do {
                                                try await homeViewModel.checkForNewBets(in: viewContext, timestamp: timestamp)
                                                homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                                                homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                                            } catch {
                                                
                                            }
                                        }
                                    } else {
                                        do {
                                            try await homeViewModel.checkForNewBets(in: viewContext, timestamp: nil)
                                        } catch {
                                            
                                        }
                                    }
                                    leagueViewModel.points = activeLeague.points ?? [:]
                                    let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == activeLeague.code })?.players
                                    
                                    if let leaguePlayers = leaguePlayers {
                                        homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
                                    }
                                    await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets.filter({$0.leagueCode == leagueViewModel.activeLeague!.code}), parlays: homeViewModel.leagueParlays.filter({$0.leagueCode == leagueViewModel.activeLeague!.code}), week: homeViewModel.currentWeek, leagueCode: activeLeague.code)
                                    
                                    homeViewModel.userBets = homeViewModel.leagueBets.filter({ $0.playerID == userID })
                                    homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == userID })
                                }
                                
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
                }
            } label: {
                Text(loggingIn ? "Logging in..." : "Login")
                    .font(.title2.bold())
                    .foregroundStyle(loggingIn ? .lion : .oW)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(loggingIn ? .oW : .lion)
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
                defaultleagueCode = ""
                authViewModel.register(withEmail: emailAddy, password: pass, username: username, fullName: fullName, userCount: homeViewModel.users.count)
                login = true
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(Color("lion"))
            .font(.title2.bold())
            .frame(width: 200)
            .tint(Color("oW"))
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.horizontal)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
    
}
