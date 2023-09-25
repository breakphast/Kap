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
    @Binding var userID: String

    @EnvironmentObject var homeViewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var weeklyPoints: Double?
    
    @State private var selectedOption = "Overall"
    @State private var week = 0
    @State private var missedBets = 0
    @State private var totalPoints: Double = 0
    
    @State private var selectedSegment = 0
    
    var body: some View {
        ZStack {
            Color("onyx").ignoresSafeArea()
            settledBetsTab
                .fontDesign(.rounded)
                .onChange(of: bets.count, perform: { _ in
                    fetchData()
                })
        }
        .task {
            fetchData()
            for parlay in parlays {
                if parlay.result == .pending {
                    BetViewModel().updateParlay(parlay: parlay)
                }
            }
            
            if week == 0 {
                missedBets = await UserViewModel().fetchAllMissedBets(for: userID, startingWeek: homeViewModel.currentWeek)
            } else {
                missedBets = await UserViewModel().fetchMissedBetsCount(for: userID, week: homeViewModel.currentWeek) ?? 0
            }
            totalPoints = homeViewModel.users.first(where: { $0.id == userID })!.totalPoints!
        }
    }

    var settledBetsTab: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 100, height: 4)
                .foregroundStyle(Color("onyxLightish"))
            
            VStack(alignment: .leading) {
                HStack {
                    Image("avatar\(homeViewModel.users.first(where: { $0.id == userID })?.avatar ?? 0)")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 30, height: 30)
                    
                    Text("\(homeViewModel.users.first(where: { $0.id == userID })!.username.uppercased())")
                        .foregroundStyle(Color("lion"))
                        .font(.title3)
                        .fontWeight(.black)
                        .kerning(0.8)
                }
                
                HStack(alignment: .center) {
                    menu
                    VStack(alignment: .leading) {
                        Text(week == 0 ? totalPoints.twoDecimalString : calculateWeeklyPoints().twoDecimalString)
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                        Text("Missing Bets: \(missedBets)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                    }
                }
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(showsIndicators: false) {
                betSection(for: .tnf, settled: true)
                if !parlays.filter({ $0.result != .pending }).isEmpty {
                    parlaySection(settled: true)
                }
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
    }
    
    func calculateWeeklyPoints() -> Double {
        let filteredBetsPoints = bets.filter { $0.week == week && $0.result != .push && $0.result != .pending }
            .reduce(0) { $0 + ($1.points ?? 0) }
        let parlayPoints = parlays.reduce(0) { $0 + ($1.totalPoints) }
        
        return filteredBetsPoints + parlayPoints
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
                    
                    ForEach(filteredBets.sorted(by: { $0.game.date < $1.game.date }), id: \.id) { bet in
                        PlacedBetView(bet: bet, bets: $bets, week: bet.week)
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
                updateForWeek(0)
            }
            ForEach(1...homeViewModel.currentWeek, id: \.self) { weekNumber in
                Button("Week \(weekNumber)", action: {
                    updateForWeek(weekNumber)
                })
            }
        } label: {
            HStack(spacing: 6) {
                Text(selectedOption.isEmpty ? (homeViewModel.activeLeague?.name ?? "") : selectedOption)
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

    private func updateForWeek(_ weekNumber: Int) {
        withAnimation {
            selectedOption = weekNumber == 0 ? "Overall" : "Week \(weekNumber)"
            week = weekNumber
            
            Task {
                do {
                    missedBets = await UserViewModel().fetchMissedBetsCount(for: userID, week: week) ?? 0
                    
                    let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                    if week == 0 {
                        bets = fetchedBets.filter { $0.playerID == userID }
                    } else {
                        bets = fetchedBets.filter { $0.playerID == userID && $0.week == weekNumber }
                    }
                    
                    let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                    if week == 0 {
                        parlays = fetchedParlays.filter { $0.playerID == userID }
                    } else {
                        parlays = fetchedParlays.filter { $0.playerID == userID && $0.week == weekNumber }
                    }
                    weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: userID, bets: bets, parlays: homeViewModel.parlays, week: weekNumber, leagueID: homeViewModel.activeLeague?.id ?? "")
                } catch {
                    print("Error fetching data for week \(weekNumber): \(error)")
                }
            }
        }
    }

    func isEmptyBets(for result: BetResult) -> Bool {
        return bets.filter { $0.result == result }.isEmpty
    }
    
    private func fetchData(_ value: Int? = nil) {
        Task {
            do {
                let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                if week == 0 {
                    bets = fetchedBets.filter { $0.playerID == userID }
                } else {
                    bets = fetchedBets.filter { $0.playerID == userID && $0.week == week }
                }
                let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                if week == 0 {
                    parlays = fetchedParlays.filter { $0.playerID == userID }
                } else {
                    parlays = fetchedParlays.filter { $0.playerID == userID && $0.week == week }
                }
                weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: userID, bets: bets, parlays: homeViewModel.parlays, week: week, leagueID: homeViewModel.activeLeague?.id ?? "")
            } catch {
                print("Error fetching bets: \(error)")
            }
        }
    }
}

