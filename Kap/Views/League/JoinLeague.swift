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
    @Binding var loggedIn: Bool
    @State private var errorText = "Invalid code. Please try again."
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
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
                                        validateCode(newValue: newValue)
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
//                                .padding(.top, 4)
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
            homeViewModel.leagueCodes = homeViewModel.leagues.map { $0.code }

        } catch {
            // If there's an error at any point, it's captured and printed here.
            // Consider whether you want to handle different errors differently or re-throw them.
            print("Failed with error: \(error.localizedDescription)")
        }
    }
    
    private func validateCode(newValue: String) {
        guard !homeViewModel.userLeagues.contains(where: {$0.code == code}) else {
            errorText = "You are already in this league.\nPlease enter a new code."
            validCode = false
            return
        }
        if homeViewModel.leagueCodes.contains(code) {
            withAnimation(.easeInOut) {
                result = true
            }
            Task {
                homeViewModel.activeleagueCode = code
                if code == "5555" {
                    leaderboardViewModel.leagueType = .season
                } else {
                    leaderboardViewModel.leagueType = .weekly
                }
                if let userID = authViewModel.currentUser?.id {
                    homeViewModel.leagues = try await leagueViewModel.fetchAllLeagues()
                    let league = homeViewModel.leagues.first(where: {$0.code == code})
                    try await leagueViewModel.addPlayerToLeague(leagueCode: league?.id ?? "", playerId: userID)
                    homeViewModel.userLeagues = try await LeagueViewModel().fetchLeaguesContainingID(id: userID)
                    if let activeLeague = homeViewModel.userLeagues.first(where: {$0.code == code}) {
                        await fetchEssentials(updateGames: false, updateScores: false, league: activeLeague, in: viewContext)
                        homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                        homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                        await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets, parlays: homeViewModel.leagueParlays, week: homeViewModel.currentWeek, leagueCode: code)
                        leagueViewModel.activeLeague = activeLeague
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        homeViewModel.activeleagueCode = code
                        if let activeLeague = leagueViewModel.activeLeague {
                            leagueViewModel.points = activeLeague.points ?? [:]
                        }
                        validCode = true
                        loggedIn = true
                    }
                }
            }
        } else {
            errorText = "Invalid code. Please try again."
            validCode = false
        }
    }
}
