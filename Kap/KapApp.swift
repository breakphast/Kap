//
//  KapApp.swift
//  Kap
//
//  Created by Desmond Fitch on 7/12/23.
//

import SwiftUI
import Firebase

@main
struct KapApp: App {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var leagueViewModel = LeagueViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()

    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Home()
                .environmentObject(homeViewModel)
                .environmentObject(authViewModel)
                .environmentObject(leagueViewModel)
                .environmentObject(leaderboardViewModel)
        }
    }
}
