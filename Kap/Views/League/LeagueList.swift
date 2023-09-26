//
//  LeagueList.swift
//  Kap
//
//  Created by Desmond Fitch on 9/26/23.
//

import SwiftUI

struct LeagueList: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var leagues: [League]
    @Binding var loggedIn: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.onyx.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(leagues.enumerated()), id: \.1.id) { index, league in
                        leagueRow(index: index, league: league)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal)
            }
            .font(.title.bold())
            .foregroundStyle(.oW)
            .fontDesign(.rounded)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.oW)
                        .onTapGesture {
                            dismiss()
                        }
                }
                ToolbarItem(placement: .principal) {
                    Text("Leagues")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.oW)
                }
            }
        }
        .onAppear {
            print(leagues.map {$0.name})
        }
    }
    
    func leagueRow(index: Int, league: League) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(index + 1)")
                    .frame(width: 24)
                    .font(.title3.bold())
                
                leagueDetailZStack(index: index, league: league)
            }
        }
        .frame(height: 60)
        .overlay(
            RoundedRectangle(cornerRadius: 1)
                .foregroundStyle(Color("onyx").opacity(0.00001))
                .onTapGesture {
                    homeViewModel.activeLeagueID = league.code
                    loggedIn.toggle()
                }
        )
    }
    
    func leagueDetailZStack(index: Int, league: League) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.lion, lineWidth: 3)
            leagueDetailHStack(for: league, index: index)
        }
    }
    
    func leagueDetailHStack(for league: League, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(.loch)
                .resizable()
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: 30)
                .shadow(color: .oW, radius: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(league.name)
                    .fontWeight(.bold)
                    .font(.title2)
            }
        }
        .padding(.horizontal)
        .padding(.trailing, index == 0 ? 1 : 0)
        .padding(.vertical, 12)
    }
}

//#Preview {
//    LeagueList()
//}
