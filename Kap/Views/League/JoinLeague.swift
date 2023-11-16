//
//  JoinLeague.swift
//  Kap
//
//  Created by Desmond Fitch on 9/25/23.
//

import SwiftUI
import CoreData

struct JoinLeague: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    @FocusState private var focusedField: Int?
    @State private var code = ""
    @State private var validCode: Bool?
    @State private var result: Bool?
    @State private var errorText = "Invalid code. Please try again."
    @Environment(\.dismiss) var dismiss
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
        NavigationStack {
            ZStack {
                Color.onyx.ignoresSafeArea()
                
                if result == true {
                    Image(systemName: "checkmark")
                        .font(.system(size: 48))
                        .bold()
                        .foregroundStyle(.bean)
                } else {
                    VStack {
                        Text("Enter Code")
                            .foregroundStyle(.oW)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(lineWidth: 4)
                                .foregroundStyle(Color("lion"))
                                .frame(height: 50)
                                .shadow(color: .oW.opacity(0.1), radius: 8, x: 2, y: 2)

                            TextField("", text: $code)
                                .font(.title.bold().width(.condensed))
                                .foregroundStyle(result == true ? .lion : .oW)
                                .padding()
                                .multilineTextAlignment(.center)
                                .frame(width: 150, alignment: .center)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.numberPad)
                                .onChange(of: code) { newValue in
                                    validCode = nil
                                    if newValue.count == 4 {
                                        Task {
                                            if let userID = authViewModel.currentUser?.id {
                                                try await ignitionSequence(userID: userID, leagueCode: code, week: homeViewModel.currentWeek)
                                            }
                                        }
                                    }
                                }
                                .focused($focusedField, equals: 0)
                                .onAppear {
                                    focusedField = 0
                                }
                        }
                        .frame(width: 150)

                        if validCode == false {
                            Text(errorText)
                                .foregroundStyle(.redd)
                                .font(.caption.bold())
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .font(.largeTitle.bold())
            .fontDesign(.rounded)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.oW)
                        .onTapGesture {
                            dismiss()
                        }
                }
            }
        }
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
    
    private func ignitionSequence(userID: String, leagueCode: String, week: Int) async throws {
        guard !homeViewModel.userLeagues.contains(where: {$0.code == code}) else {
            errorText = "You are already in this league.\nPlease enter a new code."
            validCode = false
            return
        }
        // if database has leagueCode
        if homeViewModel.leagueCodes.contains(code) {
            withAnimation(.easeInOut) {
                result = true
            }
            Task {
                //activate league in viewmodel
                homeViewModel.activeleagueCode = code
                if let userID = authViewModel.currentUser?.id {
                    // get all leagues from db
                    homeViewModel.leagues = try await leagueViewModel.fetchAllLeagues()
                    // grab league that matches code
                    let league = homeViewModel.leagues.first(where: {$0.code == code})
                    // add self to league
                    try await leagueViewModel.addPlayerToLeague(leagueCode: league?.id ?? "", playerId: userID)
                    // fetch leagues that contain user and assign to local database
                    homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: userID)
                    homeViewModel.allGameModels = self.allGameModels
                    homeViewModel.allBetModels = self.allBetModels
                    homeViewModel.allParlayModels = self.allParlayModels
                    
                    if let activeLeague = homeViewModel.userLeagues.first(where: {$0.code == code}) {
                        
                        await fetchEssentials(updateGames: false, updateScores: false, league: activeLeague, in: viewContext)
                        
                        homeViewModel.leagueBets = homeViewModel.allBets.filter({$0.leagueCode == code})
                        homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                        
                        homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == code})
                        homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                        // check for empties
                        if homeViewModel.leagueBets.isEmpty {
                            do {
                                try await BetViewModel().addInitialBets(games: homeViewModel.allGames, leagueCode: code, in: viewContext)
                                homeViewModel.allBetModels = self.allBetModels
                                homeViewModel.leagueBets = homeViewModel.allBets.filter({$0.leagueCode == code})
                                homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                            } catch {
                                print("League bets are still empty.")
                            }
                        }
                        
                        if homeViewModel.leagueParlays.isEmpty {
                            do {
                                try await ParlayViewModel().addInitialParlays(games: homeViewModel.allGames, leagueCode: code, in: viewContext)
                                homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == code})
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
                                try await BetViewModel().checkForNewBets(in: viewContext, leagueCode: code, bets: homeViewModel.allBets, parlays: Array(allParlayModels), timestamp: nil, counter: homeViewModel.counter, games: Array(homeViewModel.allGames), userID: userID)
                            } catch { }
                        }
                        
                        let filteredLeagueParlays = homeViewModel.leagueParlays.filter({$0.playerID != authViewModel.currentUser?.id})
                        if let lastParlayTimestamp = filteredLeagueParlays.last?.timestamp, lastParlayTimestamp > currentTimestamp {
                            currentTimestamp = lastParlayTimestamp
                        } else {
                            do {
                                try await ParlayViewModel().checkForNewParlays(in: viewContext, leagueCode: leagueCode, parlays: Array(allParlayModels), games: homeViewModel.weekGames, counter: homeViewModel.counter, timestamp: nil, userID: userID)
                            } catch { }
                        }
                        if filteredLeagueBets.isEmpty && filteredLeagueParlays.isEmpty {
                            homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: nil)
                        } else {
                            homeViewModel.updateLocalTimestamp(in: viewContext, timestamp: currentTimestamp)
                        }
                        do {
                            try await BetViewModel().checkForNewBets(in: viewContext, leagueCode: code, bets: homeViewModel.allBets, parlays: Array(allParlayModels), timestamp: currentTimestamp, counter: homeViewModel.counter, games: Array(homeViewModel.allGames), userID: userID)
                            homeViewModel.leagueBets = homeViewModel.allBets.filter({$0.leagueCode == homeViewModel.activeleagueCode})
                            homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                            
                            try await ParlayViewModel().checkForNewParlays(in: viewContext, leagueCode: leagueCode, parlays: Array(allParlayModels), games: homeViewModel.weekGames, counter: homeViewModel.counter, timestamp: currentTimestamp, userID: userID)
                            homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                            homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                        } catch { }
                        
                        let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == activeLeague.code })?.players
                        
                        if let leaguePlayers = leaguePlayers {
                            homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
                        }
                        
                        await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets.filter({$0.leagueCode == homeViewModel.activeleagueCode}), parlays: homeViewModel.leagueParlays.filter({$0.leagueCode == homeViewModel.activeleagueCode}), week: week, leagueCode: activeLeague.code)
                        
                        homeViewModel.userBets = homeViewModel.leagueBets.filter({ $0.playerID == userID })
                        homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == userID })
                        
                    }
                    
                    validCode = true
                    dismiss()
                }
            }
        } else {
            errorText = "Invalid code. Please try again."
            validCode = false
        }
    }
}
