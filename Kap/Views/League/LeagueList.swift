//
//  LeagueList.swift
//  Kap
//
//  Created by Desmond Fitch on 9/26/23.
//

import SwiftUI

struct LeagueList: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    
    @Environment(\.dismiss) var dismiss
    @Binding var leagues: [League]
    @Binding var loggedIn: Bool
    @State private var defaultLeague = true
    @AppStorage("defaultLeagueID") private var defaultLeagueID = ""
    
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
                    Text("Leagues")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.oW)
                }
            }
        }
    }
    
    func leagueRow(index: Int, league: League) -> some View {
        VStack(alignment: .leading) {
            leagueDetailZStack(index: index, league: league)
        }
        .frame(height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .foregroundStyle(Color("onyx").opacity(0.00001))
                .onTapGesture {
                    Task {
                        homeViewModel.activeLeagueID = league.code
                        if league.code == "5555" {
                            leaderboardViewModel.leagueType = .season
                        } else {
                            leaderboardViewModel.leagueType = .weekly
                        }
                        homeViewModel.users = try await UserViewModel().fetchAllUsers()
                        leagueViewModel.activeLeague = homeViewModel.leagues.first(where: {$0.code == league.code})
                        BetViewModel().fetchBets(games: homeViewModel.allGames) { bets in
//                            homeViewModel.bets = bets
                            homeViewModel.userBets = bets.filter({$0.playerID == authViewModel.currentUser?.id ?? "" && $0.leagueID == leagueViewModel.activeLeague?.code})
                            homeViewModel.leagueBets = bets.filter({$0.leagueID == leagueViewModel.activeLeague?.code})
                        }
                        homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                        if let activeLeague = leagueViewModel.activeLeague {
                            leagueViewModel.points = activeLeague.points ?? [:]
                            let leaguePlayers = homeViewModel.leagues.first(where: { $0.code == league.code })?.players
                            if let leaguePlayers = leaguePlayers {
                                homeViewModel.users = homeViewModel.users.filter({ leaguePlayers.contains($0.id!) })
                            }
                        }
                        await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.bets.filter({$0.leagueID == league.code}), parlays: homeViewModel.parlays.filter({$0.leagueID == league.code}), week: homeViewModel.currentWeek)
                        loggedIn = true
                        if defaultLeague {
                            defaultLeagueID = league.code
                        }
                    }
                }
        )
    }
    
    func leagueDetailZStack(index: Int, league: League) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.lion, lineWidth: 3)
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
