//
//  PlayerBetsView.swift
//  Kap
//
//  Created by Desmond Fitch on 7/16/23.
//

import SwiftUI

struct PlayerBetsView: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    @EnvironmentObject var authViewModel: AuthViewModel
    let userID: String

    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedOption = ""
    @State private var week = 0
    @State private var totalPoints: Double = 0
    
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            Color("onyx").ignoresSafeArea()
            settledBetsTab
                .fontDesign(.rounded)
        }
        .task {
            week = homeViewModel.currentWeek
            selectedOption = "Week \(week)"
        }
    }

    var settledBetsTab: some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading) {
                HStack {
                    Image("avatar\(homeViewModel.users.first(where: { $0.id == userID })!.avatar ?? 0)")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 30, height: 30)
                    
                    Text("\(homeViewModel.users.first(where: { $0.id == userID })!.username.uppercased())")
                        .foregroundStyle(Color("lion"))
                        .font(.title3)
                        .fontWeight(.black)
                        .kerning(0.8)
                    
                    Spacer()
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(.oW2)
                        .onTapGesture {
                            withAnimation {
                                dismiss()
                            }
                        }
                }
                
                HStack(alignment: .center) {
                    menu
                    let winsLosses = Utility.countWinsAndLosses(bets: homeViewModel.leagueBets.filter({$0.week == week && $0.playerID == userID}), forWeek: week)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(calculateWeeklyPoints(pointsWeek: week).oneDecimalString) Points")
                            .font(.system(.caption, design: .rounded, weight: .bold))
                        Text(winsLosses.text)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(winsLosses.color)
                    }
                }
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(showsIndicators: false) {
                betSection(settled: true)
                if !homeViewModel.leagueParlays.filter({ $0.result != "Pending" && $0.playerID == userID && $0.week == week }).isEmpty {
                    parlaySection(settled: true)
                }
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 18)
    }
    
    func calculateWeeklyPoints(pointsWeek: Int) -> Double {
        if pointsWeek == 0 {
            var pts = 0.0
            for i in 1...homeViewModel.currentWeek {
                let filteredBetsPoints = homeViewModel.leagueBets.filter { $0.week == i && $0.result != "Push" && $0.result != "Pending" && $0.playerID == userID }
                    .reduce(0) { $0 + ($1.points) }
                let parlayPoints = homeViewModel.leagueParlays.filter({$0.playerID == userID && $0.week == i && $0.result != "Push" && $0.result != "Pending" && $0.playerID == userID}).reduce(0) { $0 + ($1.totalPoints) }
                
                pts += (filteredBetsPoints + parlayPoints)
            }
            return pts
        } else {
            let filteredBetsPoints = homeViewModel.leagueBets.filter { $0.week == pointsWeek && $0.result != "Push" && $0.result != "Pending" && $0.playerID == userID }
                .reduce(0) { $0 + ($1.points) }
            let parlayPoints = homeViewModel.leagueParlays.filter({$0.playerID == userID && $0.week == pointsWeek && $0.result != "Push" && $0.result != "Pending" && $0.playerID == userID}).reduce(0) { $0 + ($1.totalPoints) }
            
            return filteredBetsPoints + parlayPoints
        }
    }

    func parlaySection(settled: Bool) -> some View {
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("PARLAY")
                        .font(.caption.bold())
                        .foregroundColor(Color("oW"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("lion"))
                        .cornerRadius(4)
                    
                    Image(systemName: "gift.fill")
                        .fontDesign(.rounded)
                        .fontWeight(.black)
                        .foregroundStyle(Color("lion"))
                        .font(.title2)
                }
                .padding(.vertical, 8)
                
                if settled {
                    ForEach(homeViewModel.leagueParlays.filter { $0.result != "Pending" && $0.playerID == userID && $0.week == week}, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                } else {
                    ForEach(homeViewModel.leagueParlays.filter { $0.result == "Pending" && $0.playerID == userID && $0.week == week}, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                }
            }
        )
    }
    
    func betSection(settled: Bool) -> some View {
        let filteredBets = homeViewModel.leagueBets.filter { bet in
            if selectedOption != "Overall" {
                (bet.result != "Pending" && bet.playerID == userID && bet.week == week)
            } else {
                (bet.result != "Pending" && bet.playerID == userID)
            }
        }
        
        if !filteredBets.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    Text("NFL")
                        .font(.caption.bold())
                        .foregroundColor(Color("oW"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("lion"))
                        .cornerRadius(4)
                    
                    ForEach(filteredBets.sorted(by: { $0.game.date ?? Date() < $1.game.date ?? Date() }), id: \.id) { bet in
                        PlacedBetView(bet: bet, week: bet.week, live: bet.game.week == homeViewModel.currentWeek && Date() > bet.game.date ?? Date() && bet.game.completed == false ? true : false, hideMenu: true)
                    }
                }
            )
        } else {
            return AnyView(
                Text("No settled bets")
                    .font(.largeTitle.bold())
                    .frame(maxHeight: .infinity, alignment: .center)
            )
        }
    }
    
    private var menu: some View {
        Menu {
            Button("Overall") {
                week = homeViewModel.currentWeek
                selectedOption = "Overall"
            }
            ForEach(1...homeViewModel.currentWeek, id: \.self) { weekNumber in
                Button("Week \(weekNumber)", action: {
                    week = weekNumber
                    selectedOption = "Week \(weekNumber)"
                })
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedOption.isEmpty ? (leagueViewModel.activeLeague!.name) : selectedOption)
                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color("onyxLightish")))
        }
        .zIndex(1000)
    }

    func isEmptyBets(for result: BetResult) -> Bool {
        return homeViewModel.leagueBets.filter { $0.result == result.rawValue && $0.playerID == userID && $0.week == week }.isEmpty
    }
}

