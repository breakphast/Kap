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
    let bet: Bet
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(bet.selectedTeam ?? "")
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("\(bet.odds > 0 ? "+" : "")\(bet.odds)")
                                    .font(.subheadline.bold())
                            }
                            
                            HStack {
                                Text(bet.type != .spread ? bet.type.rawValue : bet.betString)
                                    .font(.subheadline.bold())
                                Spacer()
                                Text("(\(bet.betOption.dayType?.rawValue ?? "") \(viewModel.currentPlayer!.bets[0].map { $0.betOption.dayType == bet.betOption.dayType }.count)/\(bet.betOption.maxBets ?? 0))")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(bet.game.awayTeam) @ \(bet.game.homeTeam)")
                                .font(.caption2.bold())
                                .lineLimit(1)
                            Text("9/12/2023")
                                .font(.caption2)
                            Text("7PM EST")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                        .frame(width: 200, alignment: .leading)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Points: \(bet.points ?? 0)")
                                    .font(.subheadline.bold())
                                RoundedRectangle(cornerRadius: 0.5)
                                    .frame(width: 80, height: 1)
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
            isValid = !viewModel.currentPlayer!.bets[0].contains(where: { $0.betString == bet.betString })
        }
    }
    
    var buttons: some View {
        VStack {
            Button {
                if !viewModel.currentPlayer!.bets[0].contains(where: { $0.id == bet.id }) {
                    BetService().placeBet(bet: bet, player: viewModel.currentPlayer!)
                    viewModel.activeButtons = [UUID]()
                    viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                }
            } label: {
                ZStack {
                    Color.onyxLight
                    Text("Place Bet")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(isValid ? .lion : .white)
                        .lineLimit(2)
                }
                .overlay {
                    Color.onyxLightish.opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
                }
                .frame(width: 80, height: 40)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
            .disabled(!isValid)
            
            Button {
                
            } label: {
                ZStack {
                    Color.redd.opacity(0.8)
                    Text("Cancel Bet")
                        .font(.caption.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                .overlay {
                    Color.onyxLightish.opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
                }
                .frame(width: 80, height: 40)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
            .disabled(!isValid)
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
                        .font(.subheadline.bold())
                        
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
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                        .frame(width: 200, alignment: .leading)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Points: \(parlay.totalPoints)")
                                    .font(.subheadline.bold())
                                RoundedRectangle(cornerRadius: 0.5)
                                    .frame(width: 70, height: 1)
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
        VStack {
            Button {
                let placedParlay = BetService().makeParlay(for: parlay.bets)
                viewModel.currentPlayer!.parlays.append(placedParlay)
                viewModel.activeButtons = [UUID]()
                viewModel.activeParlays = []
            } label: {
                ZStack {
                    Color.onyxLight
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
            
            Button {
                
            } label: {
                ZStack {
                    Color.redd.opacity(0.8)
                    Text("Cancel Parlay")
                        .font(.caption.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)
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
}


#Preview {
    Betslip()
}
