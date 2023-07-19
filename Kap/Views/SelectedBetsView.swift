//
//  SelectedBetsView.swift
//  Kap
//
//  Created by Desmond Fitch on 7/17/23.
//

import SwiftUI
import Observation

struct SelectedBetsView: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    @Environment(\.viewModel) private var viewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.onyx.ignoresSafeArea()
            
            ScrollView {
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
    }
}

struct BetView: View {
    @Environment(\.viewModel) private var viewModel
    let bet: Bet
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(bet.selectedTeam ?? "")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(bet.odds > 0 ? "+": "")\(bet.odds)")
                                .font(.subheadline.bold())
                        }
                        
                        HStack {
                            Text(bet.type != .spread ? bet.type.rawValue : bet.betString)
                                .font(.subheadline.bold())
                            Spacer()
                            Text("(SNF 1/1)")
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
                    .padding(.trailing, 20)
                    
                    VStack(alignment: .leading) {
                        Text("Points: \(bet.points ?? 0)")
                        RoundedRectangle(cornerRadius: 0.5)
                            .frame(width: 80, height: 1)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption.bold())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            
            VStack {
                Button {
                    if !viewModel.bets.contains(where: { $0.id == bet.id})  {
                        viewModel.bets.append(bet)
                        viewModel.activeButtons = [UUID]()
                        viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                    }
                } label: {
                    ZStack {
                        Color.onyxLight
                        Text("Place Bet")
                            .font(.caption.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.yellow)
                            .lineLimit(2)
                    }
                    .frame(width: 80, height: 40)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .disabled(viewModel.bets.contains(where: { $0.id == bet.id}))
                }
                .zIndex(100)
                
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
                    .frame(width: 80, height: 40)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .zIndex(100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
        }
        .frame(height: 200)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}

struct ParlayView: View {
    @Environment(\.viewModel) private var viewModel
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
                            Text("Parlay Bonus")
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
                        .frame(width: 200, height: 60, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text("Points: \(parlay.totalPoints)")
                                .font(.caption.bold())
                            RoundedRectangle(cornerRadius: 0.5)
                                .frame(width: 70, height: 1)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
                .padding([.bottom, .trailing], 12)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            
            VStack {
                Button {
                    let parlay = viewModel.activeParlays
                    viewModel.parlays.append(parlay[0])
                    viewModel.activeButtons = [UUID]()
                    viewModel.activeParlays = []
                } label: {
                    ZStack {
                        Color.onyxLight
                        Text("Place Parlay")
                            .font(.caption.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.yellow)
                            .lineLimit(2)
                    }
                    .frame(width: 100, height: 40)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .zIndex(100)
                .disabled(parlay.totalOdds < 400)
                
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
                    .frame(width: 100, height: 40)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .zIndex(100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
        }
        .frame(height: 200)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}


#Preview {
    SelectedBetsView()
}
