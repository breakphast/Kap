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
    @EnvironmentObject var leagueViewModel: LeagueViewModel

    @Environment(\.dismiss) private var dismiss
    
    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var weeklyPoints: Double?
    
    @State private var selectedOption = "Week 4"
    @State private var week = 5
    
    @State private var selectedSegment = 0
    @State private var live = false
    
    let swipeThreshold: CGFloat = 50.0
    
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Color("onyx").ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 4) {
                    Picker("", selection: $selectedSegment) {
                        Text("Active").tag(0)
                        Text("Settled").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        menu
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 8) {
                                dayTrackerElement(bets: $bets, parlays: $parlays, dayType: .tnf)
                                dayTrackerElement(bets: $bets, parlays: $parlays, dayType: .sunday)
                            }
                            HStack(spacing: 8) {
                                dayTrackerElement(bets: $bets, parlays: $parlays, dayType: .snf)
                                dayTrackerElement(bets: $bets, parlays: $parlays, dayType: .mnf)
                            }
                        }
                        .font(.system(.caption2, design: .rounded, weight: .bold))
                    }
                    .padding(.top, 8)
                    
                    if selectedSegment == 0 {
                        activeBetsTab
                    } else {
                        settledBetsTab
                    }
                }
                .gesture(swipeGesture)
                .padding(.horizontal, 16)
            }
        }
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
    
    var settledBetsTab: some View {
        VStack {
            if isEmptyBets(for: .win) && isEmptyBets(for: .loss) && isEmptyBets(for: .push) && parlays.filter({ $0.result != .pending }).isEmpty {
                Text("No settled bets")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: true)
                    if !parlays.filter({ $0.result != .pending }).isEmpty {
                        parlaySection(settled: true)
                    }
                }
            }
        }
    }
    
    var activeBetsTab: some View {
        VStack {
            if isEmptyBets(for: .pending) && parlays.filter({ $0.result == .pending }).isEmpty {
                Text("No active bets")
                    .foregroundColor(.white)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: false)
                    if !parlays.filter({ $0.result == .pending }).isEmpty {
                        parlaySection(settled: false)
                    }
                }
            }
        }
    }
    
    var menu: some View {
        Menu {
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
            .background(RoundedRectangle(cornerRadius: 8).fill(Color("onyxLightish")))
        }
        .zIndex(1000)
    }

    private func updateForWeek(_ weekNumber: Int) {
        withAnimation {
            selectedOption = "Week \(weekNumber)"
            week = weekNumber
            let currentUserId = authViewModel.currentUser?.id ?? ""
            
            Task {
                do {
                    let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                    bets = fetchedBets.filter { $0.playerID == currentUserId && $0.week == weekNumber && $0.leagueID == homeViewModel.activeLeagueID! }
                    
                    let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                    parlays = fetchedParlays.filter { $0.playerID == currentUserId && $0.week == weekNumber && $0.leagueID == homeViewModel.activeLeagueID! }
                    
                    weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: currentUserId, bets: bets, parlays: parlays, week: weekNumber)
                } catch {
                    print("Error fetching data for week \(weekNumber): \(error)")
                }
            }
        }
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
                        .cornerRadius(8)
                    
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
        let liveBets = homeViewModel.bets.filter({$0.week == homeViewModel.currentWeek && Date() > $0.game.date && $0.game.completed == false && $0.leagueID == homeViewModel.activeLeagueID!})
        
        let filteredBets = bets.filter { bet in
            (settled ? bet.result != .pending : bet.result == .pending)
        }
        
        if !filteredBets.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("POINTS: \(calculateWeeklyPoints().twoDecimalString)")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .padding(.leading, 1)
                    
                    HStack {
                        Text("NFL")
                            .font(.caption.bold())
                            .foregroundColor(Color("oW"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color("lion"))
                            .cornerRadius(8)
                        Spacer()
                        Text("• LIVE")
                            .font(.caption.bold())
                            .foregroundColor(.oW)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.redd)
                            .overlay(liveBets.isEmpty ? .gray.opacity(0.8) : .clear)
                            .cornerRadius(8)
                            .sheet(isPresented: $live) {
                                LiveBetsView(bets: liveBets, users: homeViewModel.users)
                            }
                            .onTapGesture {
                                live.toggle()
                            }
                            .disabled(liveBets.isEmpty)
                    }
                    
                    ForEach(filteredBets.sorted(by: { $0.game.date < $1.game.date }), id: \.id) { bet in
                        PlacedBetView(bet: bet, bets: bets, week: week)
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
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: swipeThreshold)
            .onEnded { value in
                let horizontalDistance = value.translation.width
                let verticalDistance = value.translation.height
                let isHorizontalSwipe = abs(horizontalDistance) > abs(verticalDistance)
                
                if isHorizontalSwipe && abs(horizontalDistance) > swipeThreshold {
                    if horizontalDistance < 0 && selectedSegment < 1 {
                        // Swipe Left: Go to next segment if available
                        withAnimation {
                            selectedSegment += 1
                        }
                    } else if horizontalDistance > 0 && selectedSegment > 0 {
                        // Swipe Right: Go to previous segment if available
                        withAnimation {
                            selectedSegment -= 1
                        }
                    }
                }
            }
    }
    
    private func fetchData(_ value: Int? = nil) {
        Task {
            do {
                let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                bets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id && $0.week == week && $0.leagueID == homeViewModel.activeLeagueID! })
                let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
                parlays = fetchedParlays.filter({ $0.playerID == authViewModel.currentUser?.id && $0.week == week })
                weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: authViewModel.currentUser?.id ?? "", bets: bets, parlays: parlays, week: week)
            } catch {
                print("Error fetching bets: \(error)")
            }
        }
    }
    
    func calculateWeeklyPoints() -> Double {
        let filteredBetsPoints = bets.filter { $0.week == week && $0.result != .push && $0.result != .pending }
            .reduce(0) { $0 + ($1.points ?? 0) }
        let parlayPoints = parlays.filter { $0.week == week && $0.result != .push && $0.result != .pending }.reduce(0) { $0 + ($1.totalPoints) }
        
        return filteredBetsPoints + parlayPoints
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

struct dayTrackerElement: View {
    @Binding var bets: [Bet]
    @Binding var parlays: [Parlay]
    let dayType: DayType
    
    var maxBets: Int {
        switch dayType {
        case .sunday:
            7
        default:
            1
        }
    }
    
    var body: some View {
        if dayType != .parlay {
            let filteredBetsCount = bets.filter { $0.game.dayType == dayType.rawValue }.count
            Text("\(dayType.rawValue) ")
            + Text("\(filteredBetsCount)").foregroundColor(filteredBetsCount < maxBets ? .redd : .bean)
            + Text("/\(maxBets)").foregroundColor(filteredBetsCount < maxBets ? .redd : .bean)
        } else {
            Text("Parlay ")
            + Text("\(parlays.count)").foregroundColor(.oW)
            + Text("/1").foregroundColor(.oW)
        }
    }
}
