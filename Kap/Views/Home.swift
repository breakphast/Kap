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
    @Environment(\.viewModel) private var viewModel
    @State private var showingSplashScreen = true
    
    var body: some View {
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
            
            Button(viewModel.activeUser?.name ?? "") {
                
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .tint(.white)
        .preferredColorScheme(.dark)
        .task {
            do {
                viewModel.users = try await UserViewModel().fetchAllUsers()
                viewModel.activeUser = viewModel.users.randomElement()
                
                print(viewModel.activeUser?.name ?? "")
                
                viewModel.games = try await GameService().fetchGamesFromFirestore().chunked(into: 16)[0]
                let _ = try await GameService().updateGameScore(game: viewModel.games[0])
                GameService().updateDayType(for: &viewModel.games)
                viewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                viewModel.activeLeague = viewModel.leagues.first
                
                viewModel.bets = try await BetViewModel().fetchBets(games: viewModel.games)
                
                viewModel.parlays = try await ParlayViewModel().fetchParlays(games: viewModel.games)
                
                let _ = await LeaderboardViewModel().generateLeaderboards(leagueID: viewModel.activeLeague?.id ?? "", users: viewModel.users, bets: viewModel.bets, weeks: [1,2])
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

#Preview {
    Home()
}

extension EnvironmentValues {
    var viewModel: AppDataViewModel {
        get { self[ViewModelKey.self] }
        set { self[ViewModelKey.self] = newValue }
    }
}

private struct ViewModelKey: EnvironmentKey {
    static var defaultValue: AppDataViewModel = AppDataViewModel()
}
