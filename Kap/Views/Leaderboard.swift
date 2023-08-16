//
//  ContentView.swift
//  kappers
//
//  Created by Desmond Fitch on 6/23/23.
//

import SwiftUI

struct Leaderboard: View {
    @Environment(\.viewModel) private var viewModel
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    @State private var users: [User] = []
    @State private var selectedOption = "Week 1"
    @State private var week = 1
    @State private var pointsDifferences: [String: Int] = [:]
    @State private var leaderboards: [[User]] = [[]]
    @State private var bigMovers: [(User, up: Bool)]?
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            VStack(alignment: .center, spacing: 8) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                
                Menu {
                    Button("Week 1", action: {
                        withAnimation {
                            selectedOption = "Week 1"
                            week = 1
                            Task {
                                users = await LeaderboardViewModel().getLeaderboardData(leagueID: viewModel.activeLeague?.id ?? "", users: viewModel.users, bets: viewModel.bets, week: 1)
                                await updatePointsDifferences()
                            }
                        }
                    })
                    Button("Week 2", action: {
                        withAnimation {
                            selectedOption = "Week 2"
                            week = 2
                            Task {
                                users = await LeaderboardViewModel().getLeaderboardData(leagueID: viewModel.activeLeague?.id ?? "", users: viewModel.users, bets: viewModel.bets, week: 2)
                                await updatePointsDifferences()
                            }
                        }
                    })
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedOption.isEmpty ? (viewModel.activeLeague?.name ?? "") : selectedOption)
                        Image(systemName: "chevron.down")
                            .font(.caption2.bold())
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                }
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(users.enumerated()), id: \.1.id) { index, user in
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(index + 1)")
                                    .frame(width: 24)
                                    .font(.title3.bold())
                                
                                ZStack(alignment: .leading) {
                                    if index == 0 {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.clear)
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .padding()
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(index == 0 ? Color("leader") : user.totalPoints ?? 0 >= 0 ? Color.bean : Color.red, lineWidth: 3)
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 20).fill(Color("onyx").opacity(0.5))
                                    }
                                    
                                    HStack {
                                        Image("avatar\(index)")
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                            .frame(width: 40)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(user.name)
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
                                            Image(systemName: pointsDifference(for: user) >= 0 ? "chevron.up.circle" : "chevron.down.circle")
                                                .font(.title2.bold())
                                                .foregroundStyle(pointsDifference(for: user) >= 0 ? Color.bean : Color.red)
                                            
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.trailing, index == 0 ? 1 : 0)
                                    .padding(.vertical, 12)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
            .padding(.top, 80)
        }
        .fontDesign(.rounded)
        .task {
            week = viewModel.currentWeek
            selectedOption = "Week \(week)"
            
            users = await LeaderboardViewModel().getLeaderboardData(leagueID: viewModel.activeLeague?.id ?? "", users: viewModel.users, bets: viewModel.bets, week: week)
            await updatePointsDifferences()
            
            leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: viewModel.activeLeague!.id!, users: viewModel.users, bets: viewModel.bets, weeks: [1, 2])
            
            bigMovers = LeaderboardViewModel().bigMover(from: leaderboards[0], to: leaderboards[1])
            
        }
        .onChange(of: viewModel.changed) { _, _ in
            Task {
                users = await LeaderboardViewModel().getLeaderboardData(leagueID: viewModel.activeLeague?.id ?? "", users: viewModel.users, bets: viewModel.bets, week: week)
                await updatePointsDifferences()
                
                leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: viewModel.activeLeague!.id!, users: viewModel.users, bets: viewModel.bets, weeks: [1, 2])
                
                bigMovers = LeaderboardViewModel().bigMover(from: leaderboards[0], to: leaderboards[1])
            }
        }
    }
    
    private func pointsDifference(for user: User) -> Int {
        return pointsDifferences[user.id ?? ""] ?? 0
    }
    
    private func updatePointsDifferences() async {
        var newPointsDifferences: [String: Int] = [:]
        for user in users {
            let diff = await LeaderboardViewModel().getWeeklyPointsDifference(user: user, bets: viewModel.bets, currentWeek: week, leagueID: viewModel.activeLeague!.id!)
            newPointsDifferences[user.id ?? ""] = diff
        }
        pointsDifferences = newPointsDifferences
    }

}

#Preview {
    Leaderboard()
}
