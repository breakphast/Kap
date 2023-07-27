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
                viewModel.users = try await UserViewModel().fetchAllUsers()
                viewModel.activeUser = viewModel.users.randomElement()
                print(viewModel.activeUser?.name ?? "")
                
                viewModel.games = try await GameService().fetchGamesFromFirestore()
                GameService().updateDayType(for: &viewModel.games)
                
                viewModel.leagues = try await LeagueViewModel().fetchAllLeagues()
                viewModel.activeLeague = viewModel.leagues.first
                
                if let user = viewModel.activeUser {
                    let _ = try await PlayerViewModel().createPlayerFromUserId(userId: user.id ?? "", leagueID: viewModel.activeLeague?.id ?? "", name: user.name)
                }
                
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
