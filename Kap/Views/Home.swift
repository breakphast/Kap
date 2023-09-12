//
//  Home.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift

struct Home: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingSplashScreen = true
    @State private var loggedIn = false
    @State private var date: Date = Date()
    
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
            .tint(Color("oW"))
            .preferredColorScheme(.dark)
            .background(.ultraThinMaterial)
            .task {
                do {
                    let activeDate = homeViewModel.formatter.string(from: Date())
                    homeViewModel.currentDate = activeDate
                    
                    homeViewModel.setCurrentWeek()
                    homeViewModel.users = try await UserViewModel().fetchAllUsers()
                    
                    homeViewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                    homeViewModel.activeLeague = homeViewModel.leagues.first
                    
                    homeViewModel.allGames = try await GameService().fetchGamesFromFirestore().chunked(into: 16)[0]
                    GameService().updateDayType(for: &homeViewModel.allGames)
                    
                    homeViewModel.games = try await GameService().fetchGamesFromFirestore().chunked(into: 16)[1]
                    GameService().updateDayType(for: &homeViewModel.games)
                    
//                    GameService().addGames(games: homeViewModel.games)
//                    let alteredGames = homeViewModel.games
//                    for game in alteredGames {
//                        try await GameService().updateGameScore(game: game)
////                        if game.completed {
////                            GameService().addGameToArchive(game: game)
////                            try await homeViewModel.deleteGame(game: game)
////                            print(game.documentId)
////                        }
//                    }
//                    homeViewModel.games = alteredGames
                    
                    homeViewModel.bets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                    homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                    for parlay in homeViewModel.parlays {
                        if parlay.result == .pending  {
                            BetViewModel().updateParlay(parlay: parlay)
                        }
                    }
                    homeViewModel.parlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                    homeViewModel.leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, weeks: [homeViewModel.currentWeek - 1, homeViewModel.currentWeek])
                    
//                    let games = try await GameService().getGames()
                    
//                    for bet in homeViewModel.bets {
////                        guard bet.result == .pending else { return }
//
//                        let result = bet.game.betResult(for: bet.betOption)
//                        if result != .pending {
//                            BetViewModel().updateBetResult(bet: bet, result: result)
//                        }
//                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.linear) {
                            self.showingSplashScreen = false
                        }
                    }
                } catch {
                    
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
    }
}
