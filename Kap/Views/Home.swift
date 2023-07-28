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
                viewModel.activeUser = viewModel.users.filter({ $0.name == "RingoMingo" }).randomElement()
                
                print(viewModel.activeUser?.name ?? "")
                
                viewModel.games = try await GameService().fetchGamesFromFirestore()
                GameService().updateDayType(for: &viewModel.games)
                
                viewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                viewModel.activeLeague = viewModel.leagues.first
                
                viewModel.bets = try await BetViewModel().fetchBets(games: viewModel.games)
                
                viewModel.parlays = try await ParlayViewModel().fetchParlays(games: viewModel.games)
                
//                let playerIDs = viewModel.activeLeague?.players.map { $0 == viewModel.activeUser?.id ?? ""}
//                viewModel.players = try await PlayerViewModel().fetchAllPlayers()
//                let _ = try await LeagueViewModel().addPlayerToLeague(leagueId: viewModel.activeLeague?.id ?? "", playerId: viewModel.activeUser?.id ?? "")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
