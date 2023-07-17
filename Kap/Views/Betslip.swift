//
//  Betslip.swift
//  Kap
//
//  Created by Desmond Fitch on 7/16/23.
//

import SwiftUI
import Observation

struct Betslip: View {
    let results: [Image] = [Image(systemName: "checkmark"), Image(systemName: "x.circle")]
    @Environment(\.viewModel) private var viewModel
    
    var body: some View {
        ZStack {
            Color.onyx.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.parlays, id: \.id) { parlay in
                        ParlayView(parlay: parlay)
                    }
                    ForEach(viewModel.bets, id: \.id) { bet in
                        BetView(bet: bet)
                    }
                }
            }
        }
    }
}

struct BetView: View {
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
                            Text(bet.type.rawValue)
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
                    .padding(.trailing, 8)
                    
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text("Points: \(bet.points ?? 0)")
                            RoundedRectangle(cornerRadius: 0.5)
                                .frame(width: 80, height: 1)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 0) {
                                Text("Result: ")
                                Text("\(bet.result == .win ? "+": "")\(bet.points ?? 0)")
                                    .foregroundStyle(bet.result == .win ? .green : .red)
                            }
                        }
                        .font(.caption.bold())
                        
                        Spacer()

                        Image(systemName: bet.result == .win ? "checkmark.circle.fill": "x.circle.fill")
                            .foregroundStyle(bet.result == .win ? .green : .red)
                            .font(.largeTitle.bold())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
        }
        .frame(height: 200)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}

#Preview {
    Betslip()
}

struct ParlayView: View {
    let parlay: Parlay
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(parlay.bets.count) Leg Parlay")
                            .font(.subheadline.bold())
                        
                        HStack {
                            Text(parlay.betString)
                                .font(.subheadline.bold())
                            Spacer()
                            Text("+\(parlay.totalOdds)")
                                .font(.subheadline.bold())
                        }
                        
                        HStack {
                            Text("")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("Parlay Bonus")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .center) {
                        VStack(alignment: .leading) {
                            Text("Points: \(parlay.totalPoints)")
                            RoundedRectangle(cornerRadius: 0.5)
                                .frame(width: 80, height: 1)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 0) {
                                Text("Result: ")
                                Text("\(parlay.result == .win ? "+": "")\(parlay.totalPoints)")
                                    .foregroundStyle(parlay.result == .win ? .green : .red)
                            }
                        }
                        .font(.caption.bold())
                        
                        Spacer()

                        Image(systemName: parlay.result == .win ? "checkmark.circle.fill": "x.circle.fill")
                            .foregroundStyle(parlay.result == .win ? .green : .red)
                            .font(.largeTitle.bold())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
        }
        .frame(height: 200)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}
