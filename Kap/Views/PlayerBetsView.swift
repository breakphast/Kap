//
//  PlayerBetsView.swift
//  Kap
//
//  Created by Desmond Fitch on 7/16/23.
//

import SwiftUI

struct PlayerBetsView: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    @Binding var userID: String

    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var weeklyPoints: Double?
    
    var body: some View {
        ZStack {
            Color("onyx").ignoresSafeArea()
            
            settledBetsTab
                .fontDesign(.rounded)
                .onChange(of: bets.count, perform: { _ in
                    fetchData()
                })
                .task {
                    fetchData()
                    for parlay in parlays {
                        if parlay.result == .pending {
                            BetViewModel().updateParlay(parlay: parlay)
                        }
                    }
                }
        }
    }

    var settledBetsTab: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 100, height: 4)
                .foregroundStyle(Color("onyxLightish"))
            
            if isEmptyBets(for: .win) && isEmptyBets(for: .loss) && isEmptyBets(for: .push) && parlays.filter({ $0.result != .pending }).isEmpty {
                Text("No settled bets")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Image("avatar\(homeViewModel.users.first(where: { $0.id == userID })?.avatar ?? 0)")
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 25, height: 25)
                        
                        Text("\(homeViewModel.users.first(where: { $0.id == userID })!.username)")
                            .foregroundStyle(Color("lion"))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    
                    Text("POINTS: \((homeViewModel.users.first(where: {$0.id == userID})?.totalPoints ?? 0).twoDecimalString)")
                        .font(.system(.body, design: .rounded, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 20)
                
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: true)
                        .padding(.top)
                    if !parlays.filter({ $0.result != .pending }).isEmpty {
                        parlaySection(settled: true)
                    }
                }
            }
        }
        .padding(.top, 12)
    }

    func parlaySection(settled: Bool) -> some View {
        return AnyView(
            VStack(alignment: .leading, spacing: 16) {
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
                .padding(.leading, 24)
                .padding(.vertical, 8)
                
                if settled {
                    ForEach(parlays.filter { $0.result != .pending }, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                } else {
                    ForEach(parlays.filter { $0.result == .pending }, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                }
            }
        )
    }
    
    func betSection(for dayType: DayType, settled: Bool) -> some View {
        let filteredBets = bets.filter { bet in
            (settled ? bet.result != .pending : bet.result == .pending)
        }
        
        if !filteredBets.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 16) {
                    Text("NFL")
                        .font(.caption.bold())
                        .foregroundColor(Color("oW"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("lion"))
                        .cornerRadius(4)
                        .padding(.leading, 24)
                    
                    ForEach(filteredBets.sorted(by: { $0.game.date < $1.game.date }), id: \.id) { bet in
                        PlacedBetView(bet: bet, bets: $bets)
                    }
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    func isEmptyBets(for result: BetResult) -> Bool {
        return bets.filter { $0.result == result }.isEmpty
    }
    
    private func fetchData(_ value: Int? = nil) {
        Task {
            do {
                let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                bets = fetchedBets.filter({ $0.playerID == userID })
                
                let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                parlays = fetchedParlays.filter({ $0.playerID == userID })
                weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: userID, bets: bets, parlays: homeViewModel.parlays, week: homeViewModel.currentWeek, leagueID: homeViewModel.activeLeague?.id ?? "")
            } catch {
                print("Error fetching bets: \(error)")
            }
        }
    }
}

