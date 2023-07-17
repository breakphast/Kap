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
    
    var body: some View {
        ZStack {
            Color.onyx.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.parlays, id: \.id) { parlay in
                        ParlayView2(parlay: parlay)
                    }
                }
            }
        }
        .onAppear {
            print(viewModel.parlays)
            print(viewModel.bets.count)
        }
    }
}

struct ParlayView2: View {
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
                            
                            VStack(alignment: .trailing) {
                                Text("+\(parlay.totalOdds)")
                                Text("Parlay Bonus")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.headline.bold())
                        
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading) {
                                Text("Chicago Bears ML")
                                Text("Baltimore Ravens ML")
                                Text("Las Vegas Raiders +7.5")
                                Text("Panthers @ Patriots O54.5")
                                Text("Chicago Bears ML")
                            }
                            .font(.caption2.bold())
                        }
                        .frame(height: 60)
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Points: \(parlay.totalPoints)")
                                .font(.body.bold())
                            RoundedRectangle(cornerRadius: 0.5)
                                .frame(width: 80, height: 1)
                                .foregroundStyle(.secondary)
                        }

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            
            VStack {
                Button {
                    let parlay = BetService().makeParlay(for: viewModel.bets, player: viewModel.players[0])
                    viewModel.parlays.append(parlay)
                    viewModel.activeButtons = [UUID]()
                    viewModel.parlaySelections = []
                } label: {
                    ZStack {
                        Color.onyxLight
                        Text("Place Bet")
                            .font(.caption.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.green)
                            .lineLimit(2)
                    }
                    .frame(width: 80, height: 40)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .zIndex(100)
                
                Button {
                    
                } label: {
                    ZStack {
                        Color.onyxLight
                        Text("Cancel Bet")
                            .font(.caption.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(Color.redd)
                            .lineLimit(2)
                    }
                    .frame(width: 80, height: 40)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
                .zIndex(100)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding()
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
