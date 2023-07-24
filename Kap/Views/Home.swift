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
            
            Button("Add games") {
                Task {
                    viewModel.addGames(games: viewModel.games)
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .tint(.white)
        .task {
            do {
                if viewModel.players.isEmpty {
                    let _ = await viewModel.getLeaderboardData()
                    await viewModel.fetchGames()
                    let _ = try await viewModel.fetchData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.smooth) {
                            self.showingSplashScreen = false
                        }
                    }
                }
            } catch {
                print("An error occurred: \(error)")
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
