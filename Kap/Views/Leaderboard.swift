//
//  ContentView.swift
//  kappers
//
//  Created by Desmond Fitch on 6/23/23.
//

import SwiftUI

struct Leaderboard: View {
    @EnvironmentObject var homeViewModel: AppDataViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    @State private var users: [User] = []
    @State private var selectedOption = "Week 1"
    @State private var week = 1
    @State private var pointsDifferences: [String: Int] = [:]
    @State private var leaderboards: [[User]] = [[]]
    @State private var bigMovers: [(User, up: Bool)]?
    @State private var points: Int = 0
    
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
            week = homeViewModel.currentWeek
            selectedOption = "Week \(week)"
            
            users = await LeaderboardViewModel().getLeaderboardData(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, week: week)
            await updatePointsDifferences()
            print(homeViewModel.currentWeek - 1)
            print(homeViewModel.currentWeek)
                        
            leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague!.id!, users: homeViewModel.users, bets: homeViewModel.bets, weeks: [1, 2])
            
            bigMovers = LeaderboardViewModel().bigMover(from: leaderboards[0], to: leaderboards[1])
            
        }
        .onChange(of: self.homeViewModel.selectedBets.count) { _, _ in
            Task {
                users = await LeaderboardViewModel().getLeaderboardData(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, week: week)
                await updatePointsDifferences()
                
                homeViewModel.bets = try await BetViewModel().fetchBets(games: homeViewModel.games)
                homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.games)
                
                leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague!.id!, users: homeViewModel.users, bets: homeViewModel.bets, weeks: [1, 2])
                
                bigMovers = LeaderboardViewModel().bigMover(from: leaderboards[0], to: leaderboards[1])
            }
        }
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
                            .stroke(week != 1 ? Color("leader") : Color.onyxLightish, lineWidth: 3)
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
                return bigMove ? Color.bean : Color.red
            }
        }
        return Color("onyxLightish")
    }
    
    var menu: some View {
        Menu {
            Button("Week 1", action: {
                withAnimation {
                    selectedOption = "Week 1"
                    week = 1
                    Task {
                        users = await LeaderboardViewModel().getLeaderboardData(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, week: 1)
                        await updatePointsDifferences()
                    }
                }
            })
            Button("Week 2", action: {
                withAnimation {
                    selectedOption = "Week 2"
                    week = 2
                    Task {
                        users = await LeaderboardViewModel().getLeaderboardData(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, week: 2)
                        await updatePointsDifferences()
                    }
                }
            })
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
                    Text("Points: \((user.totalPoints ?? 0))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    if selectedOption != "Week 1" {
                        let userPointsDifference = pointsDifference(for: user)
                        Text("\(userPointsDifference > 0 ? "+" : "")\(userPointsDifference)")
                            .font(.caption2)
                            .foregroundStyle(userPointsDifference < 0 ? .red : .bean)
                    }
                }
            }
            
            if selectedOption != "Week 1" {
                Spacer()
                Image(systemName:
                        LeaderboardViewModel().rankDifference(for: user, from: leaderboards[0], to: leaderboards[1]) > 0 ?
                      "chevron.up.circle" :
                        (LeaderboardViewModel().rankDifference(for: user, from: leaderboards[0], to: leaderboards[1]) < 0 ?
                         "chevron.down.circle" : "minus")
                )
                .font(.title2.bold())
                .foregroundStyle(LeaderboardViewModel().rankDifference(for: user, from: leaderboards[0], to: leaderboards[1]) > 0 ? Color.bean : (LeaderboardViewModel().rankDifference(for: user, from: leaderboards[0], to: leaderboards[1]) < 0 ? Color.red : Color.oW)
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
    
    private func pointsDifference(for user: User) -> Int {
        return pointsDifferences[user.id ?? ""] ?? 0
    }
    
    private func updatePointsDifferences() async {
        var newPointsDifferences: [String: Int] = [:]
        for user in users {
            let diff = await LeaderboardViewModel().getWeeklyPointsDifference(userID: user.id ?? "", bets: homeViewModel.bets, currentWeek: week, leagueID: homeViewModel.activeLeague!.id!)
            newPointsDifferences[user.id ?? ""] = diff
        }
        pointsDifferences = newPointsDifferences
    }
}

#Preview {
    Leaderboard()
}
