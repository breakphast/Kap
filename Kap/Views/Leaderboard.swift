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
    
    @State private var selectedOption = ""
    @State private var points: Int = 0
    @State private var weeklyPoints: [String: Double] = [:]
    @State private var missedCount = [String: Int]()
    @State private var selectedUserId: IdentifiableString?
    @State private var selectedWeek: Int?
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()
            VStack(alignment: .center, spacing: 8) {
                Text("Leaderboard")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                menu
            }
            scrollViewContent.padding(.top, 80)
                .fullScreenCover(item: $selectedUserId, content: { userID in
                    PlayerBetsView(userID: userID.id)
                })
        }
        .fontDesign(.rounded)
        .task {
            if selectedOption.isEmpty {
                selectedWeek = homeViewModel.currentWeek
                selectedOption = "Week \(homeViewModel.currentWeek)"
            }
        }
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
    }
    
    var menu: some View {
        Menu {
            Button("Overall", action: {
                selectedOption = "Overall"
                selectedWeek = nil
                Task {
                    weeklyPoints = [:]
                    await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets, parlays: homeViewModel.leagueParlays, games: homeViewModel.allGames, currentWeek: homeViewModel.currentWeek, week: homeViewModel.currentWeek, leagueCode: leagueViewModel.activeLeague?.code ?? "")
                }
            })
            ForEach(1...homeViewModel.currentWeek, id: \.self) { weekNumber in
                Button("Week \(weekNumber)", action: {
                    selectedOption = "Week \(weekNumber)"
                    selectedWeek = weekNumber
                    Task {
                        weeklyPoints = [:]
                        await leaderboardViewModel.generateWeeklyUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets.filter({$0.week == weekNumber}), parlays: homeViewModel.leagueParlays.filter({$0.week == weekNumber}), games: homeViewModel.allGames.filter({$0.week == weekNumber}), week: weekNumber, leagueCode: leagueViewModel.activeLeague?.code ?? "", currentWeek: homeViewModel.currentWeek)
                    }
                })
            }
        } label: {
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
            if let selectedWeek {
                userDetailHStack(for: user, index: index, missingBets: leaderboardViewModel.calculateMissingBets(user: user, games: homeViewModel.allGames, bets: homeViewModel.leagueBets, week: selectedWeek, currentWeek: homeViewModel.currentWeek))
            } else {
                userDetailHStack(for: user, index: index, missingBets: leaderboardViewModel.calculateMissingBets(user: user, games: homeViewModel.allGames, bets: homeViewModel.leagueBets, currentWeek: homeViewModel.currentWeek))
            }
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
    
    func userDetailHStack(for user: User, index: Int, missingBets: Int = 0) -> some View {
        var points: String = "0"
        var winsLosses = (text: "", color: Color.black)
        if selectedWeek != nil {
            winsLosses = Utility.countWinsAndLosses(bets: homeViewModel.leagueBets.filter({$0.week == selectedWeek ?? homeViewModel.currentWeek && $0.playerID == user.id}), forWeek: selectedWeek ?? homeViewModel.currentWeek)
        } else {
            winsLosses = Utility.countWinsAndLosses(bets: homeViewModel.leagueBets.filter({$0.playerID == user.id}), forWeek: nil)
        }
        
        if let userId = user.id {
            points = leaderboardViewModel.usersPoints[userId]?[selectedWeek ?? homeViewModel.currentWeek]?.oneDecimalString ?? 0.noDecimalString
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
                    Text("Points: \(points == "0.0" ? 0.noDecimalString : points)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text(winsLosses.text)
                        .font(.caption2.bold())
                        .foregroundStyle(winsLosses.color)
                    if missingBets > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "xmark.circle")
                            Text("\(missingBets)")
                        }
                        .foregroundStyle(.redd)
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
