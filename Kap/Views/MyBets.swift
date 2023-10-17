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
    
    @State private var weeklyPoints: Double?
    
    @State private var selectedOption = "Week 7"
    @State private var week = 7
    
    @State private var selectedSegment = 0
    @State private var live = false
    let leagueCode: String
    let userID: String
    
    init(bets: [Bet], leagueCode: String, userID: String) {
        self.leagueCode = leagueCode
        self.userID = userID
    }

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
                                dayTrackerElement(dayType: .tnf, leagueCode: leagueCode, userID: userID, filterWeek: week)
                                dayTrackerElement(dayType: .sunday, leagueCode: leagueCode, userID: userID, filterWeek: week)
                            }
                            HStack(spacing: 8) {
                                dayTrackerElement(dayType: .snf, leagueCode: leagueCode, userID: userID, filterWeek: week)
                                dayTrackerElement(dayType: .mnf, leagueCode: leagueCode, userID: userID, filterWeek: week)
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
                .padding(.horizontal, 16)
            }
            .gesture(swipeGesture)
        }
        .fontDesign(.rounded)
        .onAppear {
            selectedOption = "Week \(homeViewModel.currentWeek)"
            week = homeViewModel.currentWeek
        }
    }
    
    var settledBetsTab: some View {
        VStack {
            if isEmptyBets(for: .win) && isEmptyBets(for: .loss) && isEmptyBets(for: .push) && homeViewModel.userParlays.filter({ $0.result != .pending && $0.week == week }).isEmpty {
                Text("No settled bets")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: true)
                    if !homeViewModel.userParlays.filter({ $0.result != .pending && $0.week == week }).isEmpty {
                        parlaySection(settled: true)
                    }
                }
            }
        }
    }
    
    var activeBetsTab: some View {
        VStack {
            if isEmptyBets(for: .pending) && homeViewModel.userParlays.filter({ $0.result == .pending && $0.week == week }).isEmpty {
                Text("No active bets")
                    .foregroundColor(.white)
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView(showsIndicators: false) {
                    betSection(for: .tnf, settled: false)
                    if !homeViewModel.userParlays.filter({ $0.result == .pending && $0.week == week }).isEmpty {
                        parlaySection(settled: false)
                    }
                }
            }
        }
    }
    
    func betSection(for dayType: DayType, settled: Bool) -> some View {
        let liveBets = homeViewModel.leagueBets.filter({$0.week == homeViewModel.currentWeek && Date() > $0.game.date && $0.game.completed == false})
        
        let filteredBets = homeViewModel.userBets.filter { bet in
            (settled ? bet.result != .pending : bet.result == .pending) && bet.week == week
        }
        
        Task {
            weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: userID, bets: homeViewModel.userBets, parlays: homeViewModel.userParlays, week: week)
        }
        
        if !filteredBets.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("POINTS: \((weeklyPoints ?? 0).twoDecimalString)")
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
                        if !liveBets.isEmpty {
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
                        }
                    }
                    
                    ForEach(filteredBets.sorted(by: { $0.game.date < $1.game.date }), id: \.id) { bet in
                        PlacedBetView(bet: bet, week: week)
                    }
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    func parlaySection(settled: Bool) -> some View {
        let filteredParlays = homeViewModel.userParlays.filter { bet in
            (settled ? bet.result != .pending : bet.result == .pending)
        }
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
                    ForEach(homeViewModel.userParlays.filter { $0.result != .pending }, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                } else {
                    ForEach(homeViewModel.userParlays.filter { $0.result == .pending }, id: \.id) { parlay in
                        PlacedParlayView(parlay: parlay)
                    }
                }
            }
        )
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
                Text(selectedOption.isEmpty ? (leagueViewModel.activeLeague!.name) : selectedOption)
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
                    weeklyPoints = await LeaderboardViewModel().getWeeklyPoints(userID: currentUserId, bets: homeViewModel.userBets, parlays: homeViewModel.userParlays, week: weekNumber)
                }
            }
        }
    }

    func isEmptyBets(for result: BetResult) -> Bool {
        return homeViewModel.userBets.filter { $0.result == result && $0.leagueCode == leagueCode && $0.week == week}.isEmpty
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
    
    func calculateWeeklyPoints() -> Double {
        let filteredBetsPoints = homeViewModel.userBets.filter { $0.week == week && $0.result != .push && $0.result != .pending }
            .reduce(0) { $0 + ($1.points ?? 0) }
        let parlayPoints = homeViewModel.userParlays.filter { $0.week == week && $0.result != .push && $0.result != .pending }.reduce(0) { $0 + ($1.totalPoints) }
        
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
    @EnvironmentObject var homeViewModel: HomeViewModel
    let dayType: DayType
    let leagueCode: String
    let userID: String
    let filterWeek: Int
    
    var maxBets: Int {
        switch dayType {
        case .sunday:
            7
        default:
            1
        }
    }
    
    var body: some View {
        let newBets = homeViewModel.userBets.filter({ $0.week == filterWeek && $0.leagueCode == leagueCode})
        let filteredBetsCount = newBets.filter { $0.game.dayType == dayType.rawValue }.count
        Text("\(dayType.rawValue) ")
        + Text("\(filteredBetsCount)").foregroundColor(filteredBetsCount < maxBets ? .redd : .bean)
        + Text("/\(maxBets)").foregroundColor(filteredBetsCount < maxBets ? .redd : .bean)
    }
}
