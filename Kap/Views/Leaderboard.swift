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
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    @State private var selectedOption = "Overall"
    @State private var points: Int = 0
    @State private var weeklyPoints: [String: Double] = [:]
    @State private var userID = ""
    @State private var missedCount = [String: Int]()
    @State private var showUserBets = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            VStack(alignment: .center, spacing: 8) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                menu
            }
            scrollViewContent.padding(.top, 80)
        }
        .fontDesign(.rounded)
    }
    
    // MARK: - Subviews
    var scrollViewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(leaderboardViewModel.rankedUsers.enumerated()), id: \.1.id) { index, user in
                    userRow(index: index, user: user)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
        }
        .refreshable {
            Task {
                await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.bets.filter({$0.leagueID == leagueViewModel.activeLeague?.code}), parlays: homeViewModel.parlays.filter({$0.leagueID == leagueViewModel.activeLeague?.code}), week: homeViewModel.currentWeek)
            }
        }
    }
    
    var menu: some View {
        Menu { } label: {
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
            userDetailStrokeRoundedRectangle(for: user)
            userDetailHStack(for: user, index: index)
        }
    }

    func userDetailStrokeRoundedRectangle(for user: User) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(determineColor(for: user), lineWidth: authViewModel.currentUser?.id == user.id ? 5 : 3)
    }
    
    func determineColor(for user: User) -> Color {
        if authViewModel.currentUser?.id == user.id {
            return Color("lion")
        }

        return Color("onyxLightish")
    }

    func userDetailHStack(for user: User, index: Int) -> some View {
        
        var points: String = "0"
        
        if let userId = user.id {
            let week = homeViewModel.currentWeek
            points = leaderboardViewModel.usersPoints[userId]?[week]?.twoDecimalString ?? "0"
        }
        
        return HStack {
            Image("avatar\(user.avatar ?? 0)")
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: 40)
                .shadow(color: .oW.opacity(0.6), radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Text("Points: \(points)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    if missedCount[user.id ?? ""] ?? 0 > 0 {
                        Text("(-\(missedCount[user.id ?? ""] ?? 0))")
                            .foregroundStyle(Color("redd"))
                            .font(.caption2.bold())
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.trailing, index == 0 ? 1 : 0)
        .padding(.vertical, 12)
    }
    
    private func sortUsersByPoints() {
        homeViewModel.users.sort { user1, user2 in
            let points1 = weeklyPoints[user1.id!] ?? 0.0
            let points2 = weeklyPoints[user2.id!] ?? 0.0
            return points1 > points2
        }
    }
}
