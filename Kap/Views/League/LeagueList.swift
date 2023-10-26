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
    @Environment(\.managedObjectContext) private var viewContext

    @Environment(\.dismiss) var dismiss
    @Binding var leagues: [League]
    @Binding var loggedIn: Bool
    @State private var defaultLeague = true
    @AppStorage("defaultleagueCode") private var defaultleagueCode = ""
    
    @State private var clickedLeague = ""
    @State private var leagueToggle = false
    @State private var showingSplashScreen = false
    
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
                        showingSplashScreen.toggle()
                        withAnimation {
                            leagueToggle.toggle()
                        }
                        let activeLeague = homeViewModel.userLeagues.first(where: {$0.code == league.code})
                        
                        await homeViewModel.fetchEssentials(updateGames: false, updateScores: false, league: league, in: viewContext)
                        
                        homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                        homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
                        DispatchQueue.main.async {
                            leagueViewModel.activeLeague = activeLeague
                            homeViewModel.activeleagueCode = league.code
                            if league.code == "5555" {
                                leaderboardViewModel.leagueType = .season
                            } else {
                                leaderboardViewModel.leagueType = .weekly
                            }
                            
                            if let activeLeague = leagueViewModel.activeLeague {
                                leagueViewModel.points = activeLeague.points ?? [:]
                            }
                            Task {
                                await leaderboardViewModel.generateUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets, parlays: homeViewModel.leagueParlays, week: homeViewModel.currentWeek, leagueCode: league.code)

                                loggedIn = true
                                if defaultLeague {
                                    defaultleagueCode = league.code
                                }
                            }
                        }
                    }
                }
        )
    }

    func leagueDetailZStack(index: Int, league: League) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(leagueToggle ? .leader : Color.lion, lineWidth: leagueToggle ? 6 : 3)
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
                    .foregroundStyle(clickedLeague == league.code ? .lion : .oW)
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
