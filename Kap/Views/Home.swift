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
    
    init() {
        UITabBar.appearance().barTintColor = UIColor(named: "onyx")
    }
    
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
            .task {
                do {
                    let activeDate = homeViewModel.formatter.string(from: Date())
                    homeViewModel.currentDate = activeDate
                    
                    await homeViewModel.fetchEssentials(updateGames: false)
                    
//                    await homeViewModel.updateAndFetch()
                    
                    homeViewModel.leaderboards = await LeaderboardViewModel().generateLeaderboards(leagueID: homeViewModel.activeLeague?.id ?? "", users: homeViewModel.users, bets: homeViewModel.bets, parlays: homeViewModel.parlays, weeks: [homeViewModel.currentWeek - 1, homeViewModel.currentWeek])
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.linear) {
                            self.showingSplashScreen = false
                        }
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
    }
}
