//
//  Betslip.swift
//  Kap
//
//  Created by Desmond Fitch on 7/17/23.
//

import SwiftUI

struct Betslip: View {
    private let dismissThreshold: CGFloat = 100.0
    
    @State private var offset: CGFloat = 0.0
    @State private var shouldDismiss = false
    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var parlay: Parlay?
    
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color("onyx").ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                contentStack
            }
        }
        .task {
            await fetchData()
            if let lay = homeViewModel.activeParlays.first {
                parlay = lay
            }
        }
        .gesture(swipeGesture)
        .onChange(of: shouldDismiss, perform: { newValue in
            withAnimation { dismiss() }
        })
        .onChange(of: homeViewModel.selectedBets.count, perform: { newValue in
            withAnimation {
                guard newValue >= 2 else { return }
                updateParlay()
            }
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Betslip")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
        }
    }
    
    private func updateParlay() {
        self.parlay?.bets = homeViewModel.selectedBets
        if calculateParlayOdds(bets: homeViewModel.selectedBets) < 400 {
            parlay = nil
            homeViewModel.activeParlays = []
        }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                // Only swipe from the leading edge
                if value.startLocation.x < 50 {
                    self.offset = value.translation.width
                }
            }
            .onEnded { value in
                // Check if swipe distance is more than the threshold
                if value.translation.width > dismissThreshold {
                    shouldDismiss = true
                } else {
                    offset = 0
                }
            }
    }
    
    var contentStack: some View {
        VStack(spacing: 20) {
            ForEach(homeViewModel.selectedBets, id: \.id) { bet in
                BetView(bets: $bets, bet: bet)
            }
            
            if parlay != nil {
                ParlayView(parlays: $parlays, parlay: parlay!)
            }
        }
        .padding(.top, 20)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .onTapGesture {
                        dismiss()
                    }
            }
        }
    }
    
    private func fetchData() async {
        do {
            let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
            bets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id })
            bets = bets.filter({ $0.week == homeViewModel.currentWeek })
            
            let fetchedParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
            parlays = fetchedParlays.filter({ $0.playerID == authViewModel.currentUser?.id })
            parlays = parlays.filter({ $0.week == homeViewModel.currentWeek })
        } catch {
            print("Error fetching bets: \(error)")
        }
    }
}

struct BetView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isValid = false
    @State var isPlaced = false
    @State private var maxBets: Int = 0
    @Environment(\.dismiss) var dismiss
    @Binding var bets: [Bet]
    let bet: Bet
    
    var body: some View {
        ZStack(alignment: .center) {
            Color("onyxLightish")
            if isPlaced {
                Label("Bet placed!", systemImage: "checkmark")
                    .padding()
                    .bold()
            } else {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 12) {
                        teamAndType
                        pointsAndButtons
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding([.horizontal, .top], 24)
                    .padding(.bottom, 12)
                }
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            }
        }
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
        .task {
            isValid = bets.filter({ $0.betOption.game.documentId == bet.game.documentId }).count < 1 && bets.count < 10
            switch DayType(rawValue: bet.game.dayType ?? "") {
            case .tnf, .mnf, .snf:
                self.maxBets = 1
            default:
                self.maxBets = 7
            }
        }
        .onChange(of: bets.count) { newValue in
            isValid = bets.filter({ $0.betOption.game.documentId == bet.game.documentId }).count < 1 && bets.count < 10
        }
    }
    
    var pointsAndButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Points: \(String(format: "%.1f", bet.points ?? 0))")
                    .bold()
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 100, height: 2)
                    .foregroundStyle(.secondary)
            }
            
            buttons
                .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }
    
    var teamAndType: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bet.type == .over || bet.type == .under ? "\(bet.game.awayTeam) @ \(bet.game.homeTeam)" : bet.selectedTeam ?? "")
                    .font(bet.type == .over || bet.type == .under ? .caption2.bold() : .subheadline.bold())
                    .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .leading)
                
                Spacer()
                
                Text("\(bet.odds > 0 ? "+" : "")\(bet.odds)")
                    .font(.subheadline.bold())
            }
            .bold()
            
            HStack {
                Text(betText)
                    .font(.subheadline.bold())
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("(\(bet.betOption.game.dayType ?? "") \(bets.filter({ $0.betOption.game.dayType ?? "" == bet.betOption.game.dayType ?? "" && bet.week == homeViewModel.currentWeek }).count)/\(maxBets))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // place bet button
    var buttons: some View {
        HStack {
            Button {
                Task {
                    let placedBet = BetViewModel().makeBet(for: bet.game, betOption: bet.betOption, playerID: authViewModel.currentUser?.id ?? "", week: homeViewModel.currentWeek)
                    
                    if !bets.contains(where: { $0.game.documentId == placedBet.game.documentId }) {
                        try await BetViewModel().addBet(bet: placedBet, playerID: authViewModel.currentUser?.id ?? "")
                        
                        let fetchedBets = try await BetViewModel().fetchBets(games: homeViewModel.allGames)
                        let newBets = fetchedBets.filter({ $0.playerID == authViewModel.currentUser?.id})
                        bets = newBets.filter({ $0.week == homeViewModel.currentWeek })
                        
                        isPlaced = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                homeViewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                                if homeViewModel.selectedBets.count == 0 {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            } label: {
                ZStack {
                    Color("lion")
                    Text("Place Bet")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(isValid ? Color("oW") : .gray)
                        .lineLimit(2)
                }
                .overlay {
                    Color("onyxLightish").opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
                }
                .frame(width: 100, height: 50)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
            .disabled(!isValid)
            
            Button {
                withAnimation {
                    homeViewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                    if homeViewModel.selectedBets.isEmpty {
                        dismiss()
                    }
                }
            } label: {
                ZStack {
                    Color("oW").opacity(0.8)
                    Text("Cancel Bet")
                        .font(.caption.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(Color("redd").opacity(0.8))
                        .lineLimit(2)
                }
                .frame(width: 100, height: 50)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
        }
    }
    
    var betText: String {
        if bet.type == .over || bet.type == .under {
            let truncatedString = bet.betOption.betString.dropFirst(2).split(separator: "\n").first ?? ""
            return bet.type.rawValue + " " + truncatedString
        } else if bet.type == .spread {
            return "Spread " + bet.betString
        } else {
            return bet.type.rawValue
        }
    }
}

struct ParlayView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isValid = false
    @Binding var parlays: [Parlay]
    let parlay: Parlay
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(parlay.bets.count) Leg Parlay")
                            
                            Spacer()
                            
                            Text("+\(parlay.totalOdds)".replacingOccurrences(of: ",", with: ""))
                        }
                        .bold()
                        
                        HStack {
                            Spacer()
                            Text("Parlay Bonus (\(parlays.count)/1)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                ForEach(parlay.bets, id: \.id) { bet in
                                    Text(bet.type == .spread ? "\(bet.selectedTeam ?? "") \(bet.betString)" : bet.betString)
                                        .lineLimit(1)
                                }
                            }
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        }
                        .frame(width: 200, alignment: .leading)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Points: \(String(format: "%.1f", parlay.totalPoints))")
                                    .bold()
                                RoundedRectangle(cornerRadius: 1)
                                    .frame(width: 100, height: 2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            buttons
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
        }
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
        .onAppear {
            isValid = parlays.count == 0 && parlay.totalOdds <= 800
        }
        .onChange(of: parlays.count) { _ in
            isValid = parlays.count == 0 && parlay.totalOdds <= 800
        }
    }
    
    var buttons: some View {
        Button {
            let placedParlay = ParlayViewModel().makeParlay(for: parlay.bets, playerID: authViewModel.currentUser?.id ?? "", week: homeViewModel.currentWeek)
            Task {
                try await ParlayViewModel().addParlay(parlay: placedParlay)
                parlays.append(placedParlay)
            }
            homeViewModel.activeParlays = []
        } label: {
            ZStack {
                Color("onyxLightish")
                Text("Place Parlay")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(isValid ? Color("lion") : .white)
                    .lineLimit(2)
            }
            .overlay {
                Color("onyxLightish").opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
            }
            .frame(width: 100, height: 40)
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .zIndex(100)
        .disabled(!isValid)
    }
}
