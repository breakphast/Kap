//
//  Home.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Observation

struct Home: View {
    @Environment(\.viewModel) private var viewModel
    
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
                    Label("League", systemImage: "person.3")
                }
            
            Leaderboard()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.white)
        .task {
            if viewModel.players.isEmpty {
                let _ = await viewModel.getLeaderboardData()
           
            }
        }
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
