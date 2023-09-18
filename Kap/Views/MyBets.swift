//
//  MyBets.swift
//  Kap
//
//  Created by Desmond Fitch on 7/16/23.
//

import SwiftUI

struct MyBets: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var weeklyPoints: Double?
    
    @State private var selectedOption = "Week 2"
    @State private var week = 1
    
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack(alignment: .topLeading) {
                Color("onyx").ignoresSafeArea()
                VStack(alignment: .leading) {
                    Picker("", selection: $selectedSegment) {
                        Text("Active").tag(0)
                        Text("Settled").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    menu
                }
                .padding(.horizontal, 24)
                
                if selectedSegment == 0 {
                    activeBetsTab
                } else {
                    settledBetsTab
                }
            }
        }
        .fontDesign(.rounded)
        .onChange(of: bets.count, perform: { _ in
            fetchData()
        })
        .task {
            week = homeViewModel.currentWeek
//            selectedOption = "Week 2"
            fetchData()
            for parlay in parlays {
                if parlay.result == .pending {
                    BetViewModel().updateParlay(parlay: parlay)
                }
            }
        }
    }
    
    var settledBetsTab: some View {
        VStack(spacing: 8) {
            if isEmptyBets(for: .win) && isEmptyBets(for: .loss) && isEmptyBets(for: .push) && parlays.filter({ $0.result != .pending }).isEmpty {
                Text("No settled bets")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Text("POINTS: \((weeklyPoints ?? 0).twoDecimalString)")
                    .font(.system(.body, design: .rounded, weight: .bold))
                
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: true)
                        .padding(.top)
                    if !parlays.filter({ $0.result != .pending }).isEmpty {
                        parlaySection(settled: true)
                    }
                }
            }
        }
        .padding(.top, 50)
    }
    
    var activeBetsTab: some View {
        VStack(spacing: 8) {
            if isEmptyBets(for: .pending) && parlays.filter({ $0.result == .pending }).isEmpty {
                Text("No active bets")
                    .foregroundColor(.white)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Text("")
                    .padding(.top, 4)
                
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: false)
                    if !parlays.filter({ $0.result == .pending }).isEmpty {
                        parlaySection(settled: false)
                    }
                }
            }
        }
        .padding(.top, 60)
    }
    
    var menu: some View {
        Menu {
            Button("Week 1", action: {
                withAnimation {
                    selectedOption = "Week 1"
                    week = 1
                    Task {
                        let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                        bets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id })
                        bets = bets.filter({ $0.week == 1 })
                        
                        let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                        parlays = fetchedParlays.filter({ $0.id == $0.playerID + String(1) })
                        parlays = parlays.filter({ $0.week == 1 })
                        
                        weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: authViewModel.currentUser?.id ?? "", bets: bets, parlays: homeViewModel.parlays, week: 1, leagueID: homeViewModel.activeLeague?.id ?? "")
                    }
                }
            })
            Button("Week 2", action: {
                withAnimation {
                    selectedOption = "Week 2"
                    week = 2
                    Task {
                        let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                        bets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id })
                        bets = bets.filter({ $0.week == 2 })
                        
                        let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                        parlays = fetchedParlays.filter({ $0.playerID == authViewModel.currentUser?.id })
                        parlays = parlays.filter({ $0.week == 2 })
                        
                        weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: authViewModel.currentUser?.id ?? "", bets: bets, parlays: homeViewModel.parlays, week: 2, leagueID: homeViewModel.activeLeague?.id ?? "")
                    }
                }
            })
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
        .padding(.top, 4)
        .padding(.bottom)
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
                bets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id && $0.week == week })
                
                let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                parlays = fetchedParlays.filter({ $0.playerID == authViewModel.currentUser?.id && $0.week == week })
                weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: authViewModel.currentUser?.id ?? "", bets: bets, parlays: homeViewModel.parlays, week: week, leagueID: homeViewModel.activeLeague?.id ?? "")
            } catch {
                print("Error fetching bets: \(error)")
            }
        }
    }
    
    private func configureTabView() -> some View {
        TabView {
            activeBetsTab
                .tabItem { Text("Active Bets") }

            settledBetsTab
                .tabItem { Text("Settled Bets") }
        }
        .accentColor(.white)  // For the circle indicator
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .padding(.top, 40)
    }
}

