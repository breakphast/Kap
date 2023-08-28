//
//  Home.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Observation
import Firebase
import FirebaseFirestoreSwift

struct Home: View {
    @EnvironmentObject var homeViewModel: AppDataViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSplashScreen = true
    @State private var loggedIn = false
    
    var body: some View {
        if authViewModel.currentUser == nil || loggedIn == false {
            Login(loggedIn: $loggedIn)
        } else {
            TabView {
                Board()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                MyBets()
                    .tabItem {
                        Label("My Bets", systemImage: "checklist")
                    }
                
                Leaderboard()
                    .tabItem {
                        Label("Leaderboard", systemImage: "rosette")
                    }
                
                Profile(loggedIn: $loggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
            }
            .tint(.oW)
//            .preferredColorScheme(.dark)
            .task {
                do {
                    homeViewModel.users = try await UserViewModel().fetchAllUsers()
//                    homeViewModel.activeUser = homeViewModel.users.first(where: { $0.username == "Brokeee" })
                    
                    homeViewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                    homeViewModel.activeLeague = homeViewModel.leagues.first
                    
                    homeViewModel.games = try await GameService().fetchGamesFromFirestore().chunked(into: 16)[0]
                    GameService().updateDayType(for: &homeViewModel.games)
    //                try await GameService().updateGameScore(game: homeViewModel.games[0])
                    
                    homeViewModel.bets = try await BetViewModel().fetchBets(games: homeViewModel.games)
                    homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.games)
                    
                    homeViewModel.leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, weeks: [homeViewModel.currentWeek - 1, homeViewModel.currentWeek])
                    
    //                let games = try await GameService().getGames()
    //                GameService().addGames(games: games)
                    
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.smooth) {
                            self.showingSplashScreen = false
                        }
                    }
                } catch {
                    
                }
                
            }
            .overlay(
                Group {
                    if showingSplashScreen {
                        Color.lion
                            .ignoresSafeArea()
                            .overlay(
                                Image(.loch)
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
    }
}

#Preview {
    Home()
}
