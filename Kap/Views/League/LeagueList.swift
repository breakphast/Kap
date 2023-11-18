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
                    if homeViewModel.userLeagues.isEmpty {
                        NavigationLink(destination: JoinLeague()) {
                            joinLeagueView()
                                .frame(height: 60)
                        }
                    } else {
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
                        NavigationLink(destination: JoinLeague()) {
                            VStack {
                                Text("Join League")
                                    .font(.title3.bold())
                                    .foregroundStyle(.oW)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(.clear)
                                    .cornerRadius(8)
                                    .padding(.top)
                                
                                Button("Sign Out") {
                                    authViewModel.signOut()
                                    defaultleagueCode = ""
                                    homeViewModel.userBets = []
                                    homeViewModel.leagueBets = []
                                    homeViewModel.userLeagues = []
                                    homeViewModel.selectedBets = []
                                    homeViewModel.allParlays = []
                                    leagueViewModel.activeLeague = nil
                                    homeViewModel.leagueParlays = []
                                    homeViewModel.userParlays = []
                                    homeViewModel.activeParlay = nil
                                }
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.oW2)
                            }
                        }
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
                            try await ignitionSequence(userID: userID, leagueCode: league.code, week: homeViewModel.currentWeek, in: viewContext)
                            try await homeViewModel.pedestrianRefresh(in: viewContext, games: Array(allGameModels), bets: Array(allBetModels), parlays: Array(allParlayModels), leagueCode: league.code, userID: userID)
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

            homeViewModel.allGames = Array(allGameModels)
            homeViewModel.weekGames = homeViewModel.allGames.filter { $0.week == homeViewModel.currentWeek }

        } catch {
            print("Failed with error: \(error.localizedDescription)")
        }
    }
    
    private func ignitionSequence(userID: String, leagueCode: String, week: Int, in context: NSManagedObjectContext) async throws {
        var currentTimestampOfficial: Date?
        if allGameModels.isEmpty {
            print("No games. Adding now...")
            do {
                try await GameService().addInitialGames(in: context)
                homeViewModel.allGames = Array(allGameModels)
                do {
                    try await GameService().updateLocalGameOdds(games: Array(allGameModels).filter({$0.week == week}), week: week, in: context)
                    homeViewModel.allGames = Array(allGameModels)
                    print("Done adding games locally.")
                } catch { }
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
            
            homeViewModel.allGames = Array(allGameModels)
            homeViewModel.allBets = Array(allBetModels).filter({!$0.id.contains("parlayLeg")})
            homeViewModel.allParlays = Array(allParlayModels)
            
            await fetchEssentials(updateGames: false, updateScores: false, league: activeLeague, in: viewContext)
            homeViewModel.leagueBets = homeViewModel.allBets.filter({$0.leagueCode == homeViewModel.activeleagueCode})
            homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
            
            homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
            homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
            
            if let last = Array(homeViewModel.leagueBets).filter({$0.playerID != userID}).last {
                if let timestamp = last.timestamp {
                    homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: timestamp)
                    currentTimestampOfficial = timestamp
                    print("Current timestamp:", timestamp)
                }
            }
            
            if homeViewModel.leagueBets.isEmpty {
                do {
                    try await BetViewModel().addInitialBets(games: homeViewModel.allGames, leagueCode: activeLeague.code, in: viewContext)
                    homeViewModel.allBets = Array(allBetModels).filter({!$0.id.contains("parlayLeg")})
                    homeViewModel.leagueBets = homeViewModel.allBets.filter({$0.leagueCode == homeViewModel.activeleagueCode})
                    homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                    var currentTimestamp = Date()
                    let filteredLeagueBets = homeViewModel.leagueBets.filter({$0.playerID != authViewModel.currentUser?.id})
                    print(filteredLeagueBets.count)
                    if let lastBetTimestamp = filteredLeagueBets.last?.timestamp {
                        currentTimestamp = lastBetTimestamp
                        homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: currentTimestamp)
                    }
                } catch {
                    print("League bets are still empty.")
                }
            } else {
                do {
                    try await BetViewModel().checkForNewBets(in: viewContext, leagueCode: activeLeague.code, bets: homeViewModel.allBets, parlays: Array(allParlayModels), timestamp: currentTimestampOfficial != nil ? currentTimestampOfficial : nil, counter: homeViewModel.counter, games: Array(homeViewModel.allGames), userID: userID)
                    homeViewModel.leagueBets = homeViewModel.allBets.filter({$0.leagueCode == homeViewModel.activeleagueCode})
                    homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                    
                    try await ParlayViewModel().checkForNewParlays(in: viewContext, leagueCode: activeLeague.code, parlays: Array(allParlayModels), games: Array(homeViewModel.allGames), counter: homeViewModel.counter, timestamp: currentTimestampOfficial != nil ? currentTimestampOfficial : nil, userID: userID)
                    homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                    homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                } catch {
                    
                }
            }
            
            if homeViewModel.leagueParlays.isEmpty {
                do {
                    try await ParlayViewModel().addInitialParlays(games: homeViewModel.allGames, leagueCode: activeLeague.code, in: viewContext)
                    homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                    homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                } catch {
                    print("League parlays are still empty.")
                }
            }
            
            let filteredLeagueParlays = homeViewModel.leagueParlays.filter({$0.playerID != authViewModel.currentUser?.id})
            if let lastParlayTimestamp = filteredLeagueParlays.last?.timestamp, let currentTimestampOfficial, lastParlayTimestamp > currentTimestampOfficial {
                homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: lastParlayTimestamp)
            } else if let lastParlayTimestamp = filteredLeagueParlays.last?.timestamp, currentTimestampOfficial == nil {
                homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: lastParlayTimestamp)
            }
            
            let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == activeLeague.code })?.players
            
            if let leaguePlayers = leaguePlayers {
                homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
            }
            await leaderboardViewModel.generateWeeklyUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets.filter({$0.week == homeViewModel.currentWeek}), parlays: homeViewModel.leagueParlays.filter({$0.week == homeViewModel.currentWeek}), week: week, leagueCode: activeLeague.code)
            
            homeViewModel.userBets = homeViewModel.leagueBets.filter({ $0.playerID == userID })
            homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == userID })
        }
        
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
    
    func joinLeagueView() -> some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.oW, lineWidth: 3)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(.lion.opacity(0.0))
                }
            HStack(spacing: 12) {
                Image(.loch)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 30)
                    .shadow(color: .oW, radius: 2)
                Spacer()
                Text("Join League")
                    .fontWeight(.bold)
                    .font(.title2)
                    .foregroundStyle(.oW)
                Spacer()
                Image(.loch)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 30)
                    .shadow(color: .oW, radius: 2)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

//#Preview {
//    LeagueList()
//}
