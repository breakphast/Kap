//
//  ContentView.swift
//  kappers
//
//  Created by Desmond Fitch on 6/23/23.
//

import SwiftUI

struct Leaderboard: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    @State private var users: [User] = []
    @State private var selectedOption = "Overall"
    @State private var week = 1
    @State private var pointsDifferences: [String: Double] = [:]
    @State private var leaderboards: [[User]] = [[]]
    @State private var bigMovers: [(User, up: Bool)]?
    @State private var points: Int = 0
    
    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var weeklyPoints: Double?
    
    @State private var showUserBets = false
    @State private var userID = ""
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            VStack(alignment: .center, spacing: 8) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                menu
            }
            
            scrollViewContent
            .padding(.top, 80)
        }
        .fontDesign(.rounded)
        .task {
            do {
                week = 1
                selectedOption = "Overall"

                users = await LeaderboardViewModel().getLeaderboardData(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays)
                await updatePointsDifferences()
                
                homeViewModel.bets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                            
                leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, weeks: [1, 2])
                
                bigMovers = LeaderboardViewModel().bigMover(from: homeViewModel.leaderboards[0], to: homeViewModel.leaderboards[1])
            } catch {
                
            }
            
        }
        .onChange(of: self.homeViewModel.selectedBets.count, perform: { newValue in
            Task {
                users = await LeaderboardViewModel().getLeaderboardData(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays)
                await updatePointsDifferences()
                
                homeViewModel.bets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                
                leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague!.id!, users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, weeks: [homeViewModel.currentWeek - 1, homeViewModel.currentWeek])
                
                bigMovers = LeaderboardViewModel().bigMover(from: homeViewModel.leaderboards[0], to: homeViewModel.leaderboards[1])
            }
        })
    }
    
    var scrollViewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(users.enumerated()), id: \.1.id) { index, user in
                    userRow(index: index, user: user)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
    }
    
    func userRow(index: Int, user: User) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(index + 1)")
                    .frame(width: 24)
                    .font(.title3.bold())

                userDetailZStack(index: index, user: user)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .foregroundStyle(Color("onyx").opacity(0.00001))
                .onTapGesture {
                    withAnimation {
                        userID = user.id!
                        showUserBets.toggle()
                    }
                }
                .sheet(isPresented: $showUserBets) {
                    PlayerBetsView(userID: $userID)
                }
        )
    }

    func userDetailZStack(index: Int, user: User) -> some View {
        ZStack(alignment: .leading) {
            if index == 0 {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(week != 1 ? Color("leader") : Color("onyxLightish"), lineWidth: 3)
                    )
            } else {
                userDetailStrokeRoundedRectangle(for: user)
            }

            userDetailHStack(for: user, index: index)
        }
    }

    func userDetailStrokeRoundedRectangle(for user: User) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(determineColor(for: user), lineWidth: 3)
    }
    
    func determineColor(for user: User) -> Color {
        if week != 1 {
            if let bigMove = bigMoverDirection(for: user) {
                if homeViewModel.bets.filter({ $0.playerID == user.id }).count != 0 {
                    return bigMove ? Color("bean") : Color.red
                }
            }
        }
        return Color("onyxLightish")
    }
    
    var menu: some View {
        Menu {
            
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.isEmpty ? (homeViewModel.activeLeague?.name ?? "") : selectedOption)
                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
        }
        .disabled(true)
    }
    
    func userDetailHStack(for user: User, index: Int) -> some View {
        HStack {
            Image("avatar\(user.avatar ?? 0)")
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Text("Points: \((((user.totalPoints ?? 0))).oneDecimalString)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            
            if selectedOption != "Week 1" && homeViewModel.bets.filter({ $0.playerID == user.id }).count != 0 {
                Spacer()
                Image(systemName:
                        LeaderboardViewModel().rankDifference(for: user, from: homeViewModel.leaderboards[0], to: homeViewModel.leaderboards[1]) > 0 ?
                      "chevron.up.circle" :
                        (LeaderboardViewModel().rankDifference(for: user, from: homeViewModel.leaderboards[0], to: homeViewModel.leaderboards[1]) < 0 ?
                         "chevron.down.circle" : "minus")
                )
                .font(.title2.bold())
                .foregroundStyle(LeaderboardViewModel().rankDifference(for: user, from: homeViewModel.leaderboards[0], to: homeViewModel.leaderboards[1]) > 0 ? Color("bean") : (LeaderboardViewModel().rankDifference(for: user, from: homeViewModel.leaderboards[0], to: homeViewModel.leaderboards[1]) < 0 ? Color.red : Color("oW"))
                )
            }
        }
        .padding(.horizontal)
        .padding(.trailing, index == 0 ? 1 : 0)
        .padding(.vertical, 12)
    }

    
    private func bigMoverDirection(for user: User) -> Bool? {
        return bigMovers?.first(where: { $0.0.id == user.id })?.up
    }
    
    private func pointsDifference(for user: User) -> Double {
        return pointsDifferences[user.id ?? ""] ?? 0
    }
    
    private func updatePointsDifferences() async {
        var newPointsDifferences: [String: Double] = [:]
        for user in users {
            let diff = await LeaderboardViewModel().getWeeklyPointsDifference(userID: user.id ?? "", bets: homeViewModel.bets, parlays: homeViewModel.parlays, currentWeek: week, leagueID: homeViewModel.activeLeague!.id!)
            newPointsDifferences[user.id ?? ""] = diff
        }
        pointsDifferences = newPointsDifferences
    }
    
    private func fetchData(_ value: Int? = nil) {
        Task {
            do {
                let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                bets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id })
                
                let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                parlays = fetchedParlays.filter({ $0.playerID == authViewModel.currentUser?.id })
                
                weeklyPoints = await LeaderboardViewModel().getTotalPoints(userID: authViewModel.currentUser?.id ?? "", bets: bets, parlays: homeViewModel.parlays, leagueID: homeViewModel.activeLeague?.id ?? "")
            } catch {
                print("Error fetching bets: \(error)")
            }
        }
    }
}
