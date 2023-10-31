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
    
    @FetchRequest(
        entity: ParlayModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ParlayModel.timestamp, ascending: true)
        ]
    ) var allParlayModels: FetchedResults<ParlayModel>
    
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
            LeagueList(leagues: $homeViewModel.userLeagues)
        }
        .fullScreenCover(isPresented: $showLeagueIntro) {
            LeagueIntro()
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
                        if let userID {
                            Task {
                                try await ignitionSequence(userID: userID)
                            }
                        } else {
                            print("Login failed")
                            loginFailed = true
                            loggingIn.toggle()
                            return
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
    
    func fetchEssentials(updateGames: Bool, updateScores: Bool, league: League, in context: NSManagedObjectContext) async {
        do {
            guard let leaguePlayers = league.players else {
                // Handling the scenario where league players are unexpectedly nil.
                throw NSError(domain: "HomeViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error: league players are nil."])
            }
            
            // Fetch all relevant users asynchronously based on the league players.
            let fetchedUsers = try await UserViewModel().fetchAllUsers(leagueUsers: leaguePlayers)
            let relevantUsers = fetchedUsers.filter { leaguePlayers.contains($0.id ?? "") }
            
            // Assign the fetched and filtered users to your 'users' property.
            homeViewModel.users = relevantUsers
            
            // Populate the 'allGames' and 'weekGames' properties based on 'allGameModels'.
            if let allGameModels = homeViewModel.allGameModels {
                homeViewModel.allGames = Array(allGameModels)
                homeViewModel.weekGames = homeViewModel.allGames.filter { $0.week == homeViewModel.currentWeek }
            }
            
            // Generate the league codes based on available leagues and assign them to the 'leagueCodes' property.
            
        } catch {
            // If there's an error at any point, it's captured and printed here.
            // Consider whether you want to handle different errors differently or re-throw them.
            print("Failed with error: \(error.localizedDescription)")
        }
    }
    
    func ignitionSequence(userID: String) async throws {
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
        homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: userID)
        let defaultCode = UserDefaults.standard.string(forKey: "defaultleagueCode")
        guard defaultCode != "" else {
            homeViewModel.activeleagueCode = defaultCode
            leagueViewModel.activeLeague = homeViewModel.leagues.first(where: {$0.code == defaultCode})
            
            if let activeLeague = leagueViewModel.activeLeague {
                homeViewModel.allGameModels = self.allGameModels
                homeViewModel.allBetModels = self.allBetModels
                homeViewModel.allParlayModels = self.allParlayModels
                
                await fetchEssentials(updateGames: false, updateScores: false, league: activeLeague, in: viewContext)
                homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                if homeViewModel.leagueBets.isEmpty {
                    do {
                        try await homeViewModel.addInitialBets(games: homeViewModel.allGames, in: viewContext)
                        homeViewModel.allBetModels = self.allBetModels
                    } catch {
                        print("League bets are still empty.")
                    }
                }
                if let last = homeViewModel.leagueBets.last {
                    if let timestamp = last.timestamp {
                        homeViewModel.counter?.timestamp = timestamp
                        print("Current timestamp:", timestamp)
                        do {
                            try await homeViewModel.checkForNewBets(in: viewContext, timestamp: timestamp, games: homeViewModel.allGames)
                            homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                            homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                            try await homeViewModel.checkForNewParlays(in: viewContext, timestamp: timestamp)
                            homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                            homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                        } catch {
                            
                        }
                    }
                } else {
                    do {
                        try await homeViewModel.checkForNewBets(in: viewContext, timestamp: nil, games: homeViewModel.allGames)
                    } catch {
                        
                    }
                }
                leagueViewModel.points = activeLeague.points ?? [:]
                let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == activeLeague.code })?.players
                
                if let leaguePlayers = leaguePlayers {
                    homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
                }
                await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets.filter({$0.leagueCode == homeViewModel.activeleagueCode}), parlays: homeViewModel.leagueParlays.filter({$0.leagueCode == homeViewModel.activeleagueCode}), week: homeViewModel.currentWeek, leagueCode: activeLeague.code)
                
                homeViewModel.userBets = homeViewModel.leagueBets.filter({ $0.playerID == userID })
                homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == userID })
            }
            return
        }
        
        if homeViewModel.userLeagues.count > 0 {
            showLeagueList.toggle()
        } else {
            showLeagueIntro.toggle()
        }
    }
}
