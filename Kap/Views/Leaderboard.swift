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
    @State private var missedCount = [String: Int]()
    @State private var selectedUserId: IdentifiableString?
    
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            VStack(alignment: .center, spacing: 8) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                menu
            }
            scrollViewContent.padding(.top, 80)
                .sheet(item: $selectedUserId) { userId in
                    PlayerBetsView(userID: userId.id)
                }
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
                await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.allBets.filter({$0.leagueCode == leagueViewModel.activeLeague?.code}), parlays: homeViewModel.allParlays.filter({$0.leagueCode == leagueViewModel.activeLeague?.code}), week: homeViewModel.currentWeek, leagueCode: leagueViewModel.activeLeague?.code ?? "")
            }
        }
    }
    
    var menu: some View {
        Menu { } label: {
            HStack(spacing: 4) {
                Text(selectedOption.isEmpty ? (leagueViewModel.activeLeague!.name) : selectedOption)
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
                        if let userID = user.id {
                            selectedUserId = IdentifiableString(id: userID)
                        }
                    }
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
}

struct IdentifiableString: Identifiable {
    let id: String
}
