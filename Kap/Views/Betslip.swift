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
    
    var body: some View {
        ZStack {
            Color.onyx.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ForEach(viewModel.selectedBets, id: \.id) { bet in
                        BetView(bet: bet)
                    }
                    
                    ForEach(viewModel.activeParlays, id: \.id) { parlay in
                        ParlayView(parlay: parlay)
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
}

struct BetView: View {
    @Environment(\.viewModel) private var viewModel
    @State var isValid = true
    @State var isPlaced = false
    @Environment(\.dismiss) var dismiss
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
            isValid = viewModel.currentPlayer!.bets[0].filter({ $0.betOption.dayType == bet.betOption.dayType }).count < bet.betOption.maxBets ?? 0
        }
        .onChange(of: viewModel.currentPlayer!.bets[0].count) { oldValue, newValue in
            isValid = viewModel.currentPlayer!.bets[0].filter({ $0.betOption.dayType == bet.betOption.dayType }).count < bet.betOption.maxBets ?? 0
        }
    }
    
    var pointsAndButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Points: \(bet.points ?? 0)")
                    .bold()
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 80, height: 2)
                    .foregroundStyle(.secondary)
            }
            
            buttons
                .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }
    
    var teamAndType: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bet.selectedTeam ?? "")
                
                Spacer()
                
                Text("\(bet.odds > 0 ? "+" : "")\(bet.odds)")
            }
            .bold()
            
            HStack {
                Text(bet.type != .spread ? bet.type.rawValue : "Spread " + bet.betString)
                    .foregroundStyle(.secondary)
                    .bold()
                Spacer()
                Text("(\(bet.betOption.dayType?.rawValue ?? "") \(viewModel.currentPlayer!.bets[0].filter({ $0.betOption.dayType == bet.betOption.dayType }).count)/\(bet.betOption.maxBets ?? 0))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    var buttons: some View {
        HStack {
            Button {
                Task {
                    let placedBet = BetService().makeBet(for: bet.game, betOption: bet.betOption)
                    
                    if !viewModel.currentPlayer!.bets[0].contains(where: { $0.game.id == placedBet.game.id }) {
                        try await viewModel.addBet(bet: placedBet, player: viewModel.currentPlayer!)
                        let _ = try await viewModel.fetchData()
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
                        .foregroundStyle(isValid ? .lion : .white)
                        .lineLimit(2)
                }
                .overlay {
                    Color.onyxLightish.opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
                }
                .frame(width: 100, height: 50)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
            .disabled(!isValid)
            
            Button {
                withAnimation {
                    viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
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
}

struct ParlayView: View {
    @Environment(\.viewModel) private var viewModel
    @State var isValid = true
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
                            Text("Parlay Bonus (\(viewModel.currentPlayer!.parlays.count)/1)")
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
                                    .frame(width: 80, height: 2)
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
            isValid = viewModel.currentPlayer!.parlays.count == 0
        }
    }
    
    var buttons: some View {
        Button {
            let placedParlay = BetService().makeParlay(for: parlay.bets)
            viewModel.currentPlayer!.parlays.append(placedParlay)
            viewModel.activeParlays = []
        } label: {
            ZStack {
                Color.onyxLightish
                Text("Place Parlay")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.lion)
                    .lineLimit(2)
            }
            .overlay {
                Color.onyxLightish.opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
            }
            .frame(width: 100, height: 40)
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .zIndex(100)
        .disabled(!isValid)
    }
}


#Preview {
    Betslip()
}
