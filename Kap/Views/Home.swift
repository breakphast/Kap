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
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @State private var loggedIn = false
    @State private var date: Date = Date()
    @State private var leagues = 0
    @State private var showingSplashScreen = true
    
    init() {
        UITabBar.appearance().barTintColor = UIColor(named: "onyx")
    }
    
    var body: some View {
        if authViewModel.currentUser == nil || loggedIn == false {
            Login(loggedIn: $loggedIn)
        } else if leagueViewModel.activeLeague == nil {
            LeagueList(leagues: $homeViewModel.userLeagues, loggedIn: $loggedIn)
        } else {
            TabView {
                Board()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                MyBets(bets: homeViewModel.bets, leagueID: leagueViewModel.activeLeague?.code ?? "", userID: authViewModel.currentUser?.id ?? "")
                    .tabItem {
                        Label("My Bets", systemImage: "checklist")
                    }
                
                Leaderboard()
                    .tabItem {
                        Label("Leaderboard", systemImage: "rosette")
                    }
                
                HowToPlay()
                    .tabItem {
                        Label("Guide", systemImage: "text.book.closed.fill")
                    }
                
                Profile(loggedIn: $loggedIn)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .tint(Color("oW"))
            .preferredColorScheme(.dark)
            .task {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.linear) {
                        self.showingSplashScreen = false
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
