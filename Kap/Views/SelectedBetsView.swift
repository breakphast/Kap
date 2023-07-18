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
                    ForEach(viewModel.activeParlays, id: \.id) { parlay in
                        ParlayView2(parlay: parlay)
                    }
                }
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
                                ForEach(parlay.bets, id: \.id) { bet in
                                    Text(bet.betString)
                                        .lineLimit(1)
                                }
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
                        Text("Place Bet")
                            .font(.caption.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.yellow)
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
        .padding(20)
        .shadow(radius: 10)
    }
}


#Preview {
    SelectedBetsView()
}
