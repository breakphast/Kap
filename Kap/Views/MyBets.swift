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
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.onyx.ignoresSafeArea()
            
            TabView {
                VStack {
                    if viewModel.bets.isEmpty && viewModel.parlays.isEmpty {
                        Text("No active bets")
                            .foregroundColor(.white)
                            .font(.largeTitle.bold())
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(viewModel.bets, id: \.id) { bet in
                                    PlacedBetView(bet: bet)
                                }
                                ForEach(viewModel.parlays, id: \.id) { parlay in
                                    PlacedParlayView(parlay: parlay)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                }
                .tabItem { Text("Active Bets") }
                
                VStack {
                    Text("Settled")
                        .foregroundColor(.white)
                        .font(.largeTitle.bold())
                }
                .tabItem { Text("Settled") }
            }
            .accentColor(.white)  // For the circle indicator
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
        .fontDesign(.rounded)
    }
}

// Note: The ParlayView structure was not given in the initial code, so it's not included here.

#Preview {
    MyBets()
}

struct PlacedBetView: View {
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
                        Text("Points: \(abs(bet.points!))")
                        RoundedRectangle(cornerRadius: 0.5)
                            .frame(width: 80, height: 1)
                            .foregroundStyle(.secondary)
                        if bet.result != .pending {
                            HStack(spacing: 0) {
                                Text("Result: ")
                                Text("\(bet.result == .win ? "+": "")\(bet.points ?? 0)")
                                    .foregroundStyle(bet.result == .win ? .green : .red)
                            }
                        }
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
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
            
            Image(systemName: "trash")
                .foregroundColor(Color.onyxLight.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .padding(.bottom, 8)
        }
        .frame(height: 200)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}

struct PlacedParlayView: View {
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
                        
                        Spacer()
                        
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
                            Text("Points: \(abs(parlay.totalPoints))")
                            RoundedRectangle(cornerRadius: 0.5)
                                .frame(width: 80, height: 1)
                                .foregroundStyle(.secondary)
//                            if parlay.result == .push {
//                                HStack(spacing: 0) {
//                                    Text("Result: ")
//                                    Text("\(parlay.result == .win ? "+": "")\(parlay.totalPoints)")
//                                        .foregroundStyle(parlay.result == .win ? .green : .red)
//                                }
//                            }
                        }
                        .font(.caption.bold())
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
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
            
            Image(systemName: "trash")
                .foregroundColor(Color.onyxLight.opacity(0.9))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .padding(.bottom, 8)
        }
        .frame(height: 200)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}
