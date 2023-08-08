//
//  Betslip.swift
//  Kap
//
//  Created by Desmond Fitch on 7/17/23.
//

import SwiftUI
import Observation

struct Betslip: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    @Environment(\.viewModel) private var viewModel
    @Environment(\.dismiss) var dismiss
    
    private let dismissThreshold: CGFloat = 100.0
    @State private var offset: CGFloat = 0.0
    @State private var shouldDismiss = false
    @State private var bets: [Bet] = []
    @State private var parlays: [Parlay] = []
    @State private var allDisabled = true
    
    var body: some View {
        ZStack {
            Color.onyx.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(viewModel.selectedBets, id: \.id) { bet in
                        BetView(bets: $bets, allDisabled: $allDisabled, bet: bet)
                    }
                    
                    ForEach(viewModel.activeParlays, id: \.id) { parlay in
                        ParlayView(parlays: $parlays, allDisabled: $allDisabled, parlay: parlay)
                    }
                }
                .padding(.top, 20)
                .navigationBarBackButtonHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .onTapGesture {
                                dismiss()
                            }
                    }
                }
            }
        }
        .task {
            await fetchData()
        }
        .gesture(
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
        )
        .onChange(of: shouldDismiss, { oldValue, newValue in
            withAnimation {
                dismiss()
            }
        })
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Betslip")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
        }
    }
    
    private func fetchData() async {
        do {
            let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
            bets = fetchedBets.filter({ $0.playerID == viewModel.activeUser?.id })
            bets = bets.filter({ $0.week == viewModel.currentWeek })
            
            let fetchedParlays = try await ParlayViewModel().fetchParlays(games: viewModel.games)
            parlays = fetchedParlays.filter({ $0.playerID == viewModel.activeUser?.id ?? ""})
            parlays = parlays.filter({ $0.week == viewModel.currentWeek })
            
            allDisabled = false
        } catch {
            print("Error fetching bets: \(error)")
        }
    }
}

struct BetView: View {
    @Environment(\.viewModel) private var viewModel
    @State var isValid = false
    @State var isPlaced = false
    @Environment(\.dismiss) var dismiss
    @Binding var bets: [Bet]
    @Binding var allDisabled: Bool
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
        .onAppear {
            isValid = bets.filter({ $0.betOption.dayType == bet.betOption.dayType }).count < bet.betOption.maxBets ?? 0
            isValid = bets.filter({ $0.betOption.game.id == bet.game.id }).count < 1
        }
        .onChange(of: bets.count) { oldValue, newValue in
            isValid = bets.filter({ $0.betOption.dayType == bet.betOption.dayType }).count < bet.betOption.maxBets ?? 0
            isValid = bets.filter({ $0.betOption.game.id == bet.game.id }).count < 1
        }
    }
    
    var pointsAndButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Points: \(bet.points ?? 0)")
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
                Text("(\(bet.betOption.dayType?.rawValue ?? "") \(bets.filter({ $0.betOption.dayType == bet.betOption.dayType && bet.week == viewModel.currentWeek }).count)/\(bet.betOption.maxBets ?? 0))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    var buttons: some View {
        HStack {
            Button {
                Task {
                    let placedBet = BetViewModel().makeBet(for: bet.game, betOption: bet.betOption, playerID: viewModel.activeUser?.id ?? "", week: viewModel.currentWeek)
                    
                    if !bets.contains(where: { $0.game.id == placedBet.game.id }) {
                        try await BetViewModel().addBet(bet: placedBet)
                        
                        let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
                        let newBets = fetchedBets.filter({ $0.playerID == viewModel.activeUser?.id })
                        bets = newBets.filter({ $0.week == viewModel.currentWeek })
                        
                        isPlaced = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                                if viewModel.selectedBets.count == 0 {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            } label: {
                ZStack {
                    Color.onyxLightish
                    Text("Place Bet")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(isValid || allDisabled ? .lion : .white)
                        .lineLimit(2)
                }
                .overlay {
                    Color.onyxLightish.opacity(isValid || allDisabled ? 0.0 : 0.7).ignoresSafeArea()
                }
                .frame(width: 100, height: 50)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
            .disabled(!isValid || allDisabled)
            
            Button {
                withAnimation {
                    viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                    if viewModel.selectedBets.isEmpty {
                        dismiss()
                    }
                }
            } label: {
                ZStack {
                    Color.redd.opacity(0.8)
                    Text("Cancel Bet")
                        .font(.caption.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
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
    @Environment(\.viewModel) private var viewModel
    @State var isValid = true
    @Binding var parlays: [Parlay]
    @Binding var allDisabled: Bool
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
                                Text("Points: \(parlay.totalPoints)")
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
            isValid = parlays.count == 0
        }
        .onChange(of: parlays.count) { _, _ in
            isValid = parlays.count == 0
        }
    }
    
    var buttons: some View {
        Button {
            let placedParlay = ParlayViewModel().makeParlay(for: parlay.bets, playerID: viewModel.activeUser?.id ?? "", week: viewModel.currentWeek)
            Task {
                try await ParlayViewModel().addParlay(parlay: placedParlay)
                parlays.append(placedParlay)
            }
            viewModel.activeParlays = []
        } label: {
            ZStack {
                Color.onyxLightish
                Text("Place Parlay")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(isValid || allDisabled ? .lion : .white)
                    .lineLimit(2)
            }
            .overlay {
                Color.onyxLightish.opacity(isValid || allDisabled ? 0.0 : 0.7).ignoresSafeArea()
            }
            .frame(width: 100, height: 40)
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .zIndex(100)
        .disabled(!isValid || allDisabled)
    }
}


#Preview {
    Betslip()
}
