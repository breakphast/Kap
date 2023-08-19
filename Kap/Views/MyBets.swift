//
//  MyBets.swift
//  Kap
//
//  Created by Desmond Fitch on 7/16/23.
//

import SwiftUI
import Observation

struct MyBets: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    
    @Environment(\.viewModel) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var weeklyPoints: Int?
    
    @State private var selectedOption = "Week 1"
    @State private var week = 1
    
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack(spacing: 40) {
            ZStack(alignment: .topLeading) {
                Color.onyx.ignoresSafeArea()
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
        .onChange(of: bets.count, { _, _ in
            fetchData()
        })
        .task { 
            week = viewModel.currentWeek
            selectedOption = "Week \(week)"
            fetchData()
        }
    }
    
    var settledBetsTab: some View {
        VStack(spacing: 8) {
            if isEmptyBets(for: .win) && isEmptyBets(for: .loss) && isEmptyBets(for: .push) {
                Text("No settled bets")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Text("POINTS: \(weeklyPoints ?? 0)")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .padding(.top, 4)
                
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: true)
                        .padding(.top)
                    betSection(for: .sunday, settled: true)
                    betSection(for: .snf, settled: true)
                    betSection(for: .mnf, settled: true)
                    
                    ForEach(parlays.filter { $0.result != .pending }, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                }
                .padding(.top)
            }
        }
        .padding(.top, 50)
    }
    
    var activeBetsTab: some View {
        VStack(spacing: 8) {
            if isEmptyBets(for: .pending) {
                Text("No active bets")
                    .foregroundColor(.white)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: false)
                        .padding(.top)
                    betSection(for: .sunday, settled: false)
                    betSection(for: .snf, settled: false)
                    betSection(for: .mnf, settled: false)
                    
                    ForEach(parlays.filter { $0.result == .pending }, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                }
                .padding(.top, 40)
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
                        let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
                        bets = fetchedBets.filter({ $0.playerID == viewModel.activeUserID })
                        bets = bets.filter({ $0.week == 1 })
                        
                        let fetchedParlays = try await ParlayViewModel().fetchParlays(games: viewModel.games)
                        parlays = fetchedParlays.filter({ $0.playerID == viewModel.activeUserID })
                        parlays = parlays.filter({ $0.week == 1 })
                        
                        weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: viewModel.activeUserID, bets: bets, week: 1, leagueID: viewModel.activeLeague?.id ?? "")
                    }
                }
            })
            Button("Week 2", action: {
                withAnimation {
                    selectedOption = "Week 2"
                    week = 2
                    Task {
                        let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
                        bets = fetchedBets.filter({ $0.playerID == viewModel.activeUserID })
                        bets = bets.filter({ $0.week == 2 })
                        
                        let fetchedParlays = try await ParlayViewModel().fetchParlays(games: viewModel.games)
                        parlays = fetchedParlays.filter({ $0.playerID == viewModel.activeUserID })
                        parlays = parlays.filter({ $0.week == 2 })
                        
                        weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: viewModel.activeUserID, bets: bets, week: 2, leagueID: viewModel.activeLeague?.id ?? "")
                    }
                }
            })
        } label: {
            HStack(spacing: 4) {
                Text(selectedOption.isEmpty ? (viewModel.activeLeague?.name ?? "") : selectedOption)
                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(.onyxLightish))
        }
        .zIndex(1000)
        .padding(.top, 10)
//        .padding(.leading, 24)
    }
    
    func betSection(for dayType: DayType, settled: Bool) -> some View {
        let filteredBets = bets.filter { bet in
            (settled ? bet.result != .pending : bet.result == .pending) && bet.betOption.dayType == dayType
        }
        
        if !filteredBets.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 16) {
                    Text(dayType.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(.oW)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.lion)
                        .cornerRadius(4)
                        .padding(.leading, 24)
                        .padding(.vertical, 8)
                    
                    ForEach(filteredBets, id: \.id) { bet in
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
                let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
                bets = fetchedBets.filter({ $0.playerID == viewModel.activeUserID && $0.week == week })
                
                let fetchedParlays = try await ParlayViewModel().fetchParlays(games: viewModel.games)
                parlays = fetchedParlays.filter({ $0.playerID == viewModel.activeUserID && $0.week == (value != nil ? viewModel.currentWeek : 1) })
                
                weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: viewModel.activeUserID, bets: bets, week: week, leagueID: viewModel.activeLeague?.id ?? "")
            } catch {
                print("Error fetching bets: \(error)")
            }
        }
    }
    
    private func configureTabView() -> some View {
        TabView {
            activeBetsTab
//                .padding(.top, 40)
                .tabItem { Text("Active Bets") }

            settledBetsTab
//                .padding(.top, 40)
                .tabItem { Text("Settled Bets") }
        }
        .accentColor(.white)  // For the circle indicator
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .padding(.top, 40)
    }
}

#Preview {
    MyBets()
}
