//
//  LeagueList.swift
//  Kap
//
//  Created by Desmond Fitch on 9/26/23.
//

import SwiftUI
import CoreData

struct LeagueList: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(\.dismiss) var dismiss
    @Binding var leagues: [League]
    @Binding var loggedIn: Bool
    @State private var defaultLeague = true
    @AppStorage("defaultleagueCode") private var defaultleagueCode = ""
    
    @State private var clickedLeague = ""
    @State private var leagueToggle = false
    @State private var showingSplashScreen = false
    
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
        NavigationStack {
            ZStack {
                Color.onyx.ignoresSafeArea()
                VStack(alignment: .center, spacing: 12) {
                    ForEach(Array(leagues.enumerated()), id: \.1.id) { index, league in
                        leagueRow(index: index, league: league)
                    }
                    ZStack {
                        HStack(spacing: 2) {
                            Text("Set as default")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Toggle("", isOn: $defaultLeague)
                            .toggleStyle(.switch).tint(.lion)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 100)
                    Spacer()
                    NavigationLink(destination: JoinLeague(loggedIn: $loggedIn)) {
                        Text("Join League")
                            .font(.title3.bold())
                            .foregroundStyle(.oW)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(.clear)
                            .cornerRadius(8)
                            .padding(.top)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal)
            }

            .font(.title.bold())
            .foregroundStyle(.oW)
            .fontDesign(.rounded)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(homeViewModel.userLeagues.isEmpty ? "" : "Leagues")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.oW)
                }
            }
        }
        .overlay(
            Group {
                if showingSplashScreen {
                    Color("lion")
                        .ignoresSafeArea()
                        .overlay(
                            Image("loch")
                                .resizable()
                                .frame(width: 200, height: 200)
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 40))
                                .shadow(radius: 4)
                        )
                }
            }
        )
    }
    
    func leagueRow(index: Int, league: League) -> some View {
        VStack(alignment: .leading) {
            leagueDetailZStack(index: index, league: league)
        }
        .frame(height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .foregroundStyle(.onyx.opacity(0.00001))
                .onTapGesture {
                    Task {
                        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                            clickedLeague = league.code
                        }
                        if let userID = authViewModel.currentUser?.id {
                            try await ignitionSequence(userID: userID, leagueCode: league.code)
                        }
                    }
                }
        )
    }
    
    func fetchEssentials(updateGames: Bool, updateScores: Bool, league: League, in context: NSManagedObjectContext) async {
        do {
            guard let leaguePlayers = league.players else {
                throw NSError(domain: "HomeViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error: league players are nil."])
            }

            let fetchedUsers = try await UserViewModel().fetchAllUsers(leagueUsers: leaguePlayers)
            let relevantUsers = fetchedUsers.filter { leaguePlayers.contains($0.id ?? "") }

            homeViewModel.users = relevantUsers

            if let allGameModels = homeViewModel.allGameModels {
                homeViewModel.allGames = Array(allGameModels)
                homeViewModel.weekGames = homeViewModel.allGames.filter { $0.week == homeViewModel.currentWeek }
            }

        } catch {
            print("Failed with error: \(error.localizedDescription)")
        }
    }
    
    private func ignitionSequence(userID: String, leagueCode: String) async throws {
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
                    } catch { }
                }
            } catch {
                
            }
        }
        homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: userID)
        leagueViewModel.activeLeague = homeViewModel.leagues.first(where: {$0.code == leagueCode})
        homeViewModel.activeleagueCode = leagueCode
        
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
                    homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                    homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                } catch {
                    print("League bets are still empty.")
                }
            }
            if homeViewModel.leagueParlays.isEmpty {
                do {
                    try await homeViewModel.addInitialParlays(games: homeViewModel.allGames, in: viewContext)
                    homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                    homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                } catch {
                    print("League parlays are still empty.")
                }
            }
            var currentTimestamp = Date()
            let filteredLeagueBets = homeViewModel.leagueBets.filter({$0.playerID != authViewModel.currentUser?.id})
            if let lastBetTimestamp = filteredLeagueBets.last?.timestamp {
                currentTimestamp = lastBetTimestamp
            } else {
                do {
                    try await homeViewModel.checkForNewBets(in: viewContext, timestamp: nil, games: homeViewModel.allGames)
                } catch { }
            }
            
            let filteredLeagueParlays = homeViewModel.leagueParlays.filter({$0.playerID != authViewModel.currentUser?.id})
            if let lastParlayTimestamp = filteredLeagueParlays.last?.timestamp, lastParlayTimestamp > currentTimestamp {
                currentTimestamp = lastParlayTimestamp
            } else {
                do {
                    try await homeViewModel.checkForNewParlays(in: viewContext, timestamp: nil)
                } catch { }
            }
            if filteredLeagueBets.isEmpty && filteredLeagueParlays.isEmpty {
                homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: nil)
            } else {
                homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: currentTimestamp)
            }
            do {
                try await homeViewModel.checkForNewBets(in: viewContext, timestamp: currentTimestamp, games: homeViewModel.allGames)
                homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                
                try await homeViewModel.checkForNewParlays(in: viewContext, timestamp: currentTimestamp)
                homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
            } catch {
                
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
        
        loggedIn = true
        return
    }
    
    
    func leagueDetailZStack(index: Int, league: League) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(clickedLeague == league.code ? .lion : .oW, lineWidth: clickedLeague == league.code ? 4: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.lion.opacity(clickedLeague == league.code ? 1.0 : 0.0))
                }
            leagueDetailHStack(for: league, index: index)
        }
    }
    
    func leagueDetailHStack(for league: League, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(.loch)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: 30)
                .shadow(color: .oW, radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(league.name)
                    .fontWeight(.bold)
                    .font(.title2)
                    .foregroundStyle(.oW)
            }
        }
        .padding(.horizontal)
        .padding(.trailing, index == 0 ? 1 : 0)
        .padding(.vertical, 12)
    }
}

//#Preview {
//    LeagueList()
//}
