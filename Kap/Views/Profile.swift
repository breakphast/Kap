//
//  Profile.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct Profile: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel

    @State var user: User?
    @AppStorage("defaultleagueCode") private var defaultleagueCode = ""
    
    var body: some View {
        ZStack {
            Color("onyx").ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text(user?.username ?? "")
                    .bold()
                    .task {
                        UserService().fetchUser(withUid: authViewModel.currentUser?.id ?? "", completion: { user in
                            self.user = user
                        })
                    }
                
                Button("Sign Out") {
                    authViewModel.signOut()
                    defaultleagueCode = ""
                    homeViewModel.userBets = []
                    homeViewModel.leagueBets = []
                    homeViewModel.userLeagues = []
                    homeViewModel.selectedBets = []
                    homeViewModel.allParlays = []
                    leagueViewModel.activeLeague = nil
                    homeViewModel.leagueParlays = []
                    homeViewModel.userParlays = []
                    homeViewModel.activeParlay = nil
                }
                .font(.title2)
                .bold()
                .foregroundStyle(Color("onyx"))
                .buttonStyle(.borderedProminent)
            }
        }
        .preferredColorScheme(.dark)
    }
}

//#Preview {
//    Profile()
//}
