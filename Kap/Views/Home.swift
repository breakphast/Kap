//
//  Home.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Observation
import Firebase
//import FirebaseFirestore
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
            
            Board()
                .tabItem {
                    Label("Leaderboard", systemImage: "rosette")
                }
            
            Button("Add games") {
                Task {
                    GameService().addGames(games: viewModel.games)
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .tint(.white)
        .task {
            do {
                var games = try await GameService().fetchGamesFromFirestore()
                GameService().updateDayType(for: &games)
                viewModel.games = games
                
                let leagueViewModel = LeagueViewModel()
                
                // Creating a new league
                let newLeagueId = try await leagueViewModel.createNewLeague(league: League(id: UUID().uuidString, name: "LOWNG JOwn", players: []))
                
                // Create a new player from the user ID
                let playerId = try await leagueViewModel.createPlayerFromUserId(userId: viewModel.users[0].id ?? "")
                
                // Add this player to the newly created league
                try await leagueViewModel.addPlayerToLeague(leagueId: newLeagueId, playerId: playerId)
            } catch {
                print("Error fetching games: \(error)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.smooth) {
                    self.showingSplashScreen = false
                }
            }
        }
        .overlay(
            Group {
                if showingSplashScreen {
                    Color.lion
                        .ignoresSafeArea()
                        .overlay(
                            Image(.mün)
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
