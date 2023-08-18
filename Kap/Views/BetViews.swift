//
//  BetViews.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct PlacedBetView: View {
    @Environment(\.viewModel) private var viewModel
    @State var deleteActive = false
    @Namespace var trash
    let bet: Bet
    @Binding var bets: [Bet]
    
    func pointsColor(for result: BetResult) -> Color {
        switch result {
        case .win:
            return .bean
        case .loss:
            return .redd
        case .push, .pending:
            return .primary
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(bet.type == .over || bet.type == .under ? "\(bet.game.awayTeam) @ \(bet.game.homeTeam)" : bet.selectedTeam ?? "")
                                .font(bet.type == .over || bet.type == .under ? .caption2.bold() : .subheadline.bold())
                            Spacer()
                            Text("\(bet.odds > 0 ? "+": "")\(bet.odds)")
                                .font(.subheadline.bold())
                        }
                        
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
                            .foregroundStyle(pointsColor(for: bet.result ?? .pending))
                        RoundedRectangle(cornerRadius: 1)
                            .frame(width: 100, height: 2)
                            .foregroundStyle(.secondary)
                    }
                    .bold()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            
            VStack {
                Image(systemName: bet.result == .win ? "checkmark.circle" : bet.result == .loss ? "xmark.circle" : "hourglass.circle")
                    .font(.largeTitle.bold())
                    .foregroundColor(bet.result == .win ? .bean : bet.result == .loss ? .redd : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
            
            if deleteActive {
                HStack(spacing: 14) {
                    Image(systemName: "xmark")
                        .foregroundColor(.redd)
                        .font(.title.bold())
                        .fontDesign(.rounded)
                        .padding(.bottom, 12)
                        .onTapGesture {
                            withAnimation {
                                deleteActive.toggle()
                            }
                        }
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.bean)
                        .font(.title.bold())
                        .fontDesign(.rounded)
                        .padding(.bottom, 12)
                        .onTapGesture {
                            withAnimation {
                                deleteActive.toggle()
                                Task {
                                    let _ = try await BetViewModel().deleteBet(betID: bet.id.uuidString)
                                    bets.removeAll(where: { $0.id.uuidString == bet.id.uuidString })
                                }
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
                .matchedGeometryEffect(id: "trash", in: trash)
            } else if bet.result == .pending {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .padding(.bottom, 12)
                    .onTapGesture {
                        withAnimation {
                            deleteActive.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: "trash", in: trash)
            }
        }
        .frame(height: 180)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
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

struct PlacedParlayView: View {
    @Environment(\.viewModel) private var viewModel
    @State var deleteActive = false
    @Namespace var trash
    let parlay: Parlay
    
    @State private var formattedBets = [String]()
    @State private var legs: Int = 0
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(legs) Leg Parlay")
                            
                            Spacer()
                            
                            Text("+\(parlay.totalOdds)".replacingOccurrences(of: ",", with: ""))
                        }
                        .font(.subheadline.bold())
                        
                        HStack(alignment: .top) {
                            ScrollView(showsIndicators: false) {
                                VStack(alignment: .leading) {
                                    ForEach(formattedBets, id: \.self) { bet in
                                        Text(bet).lineLimit(1)
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }
                            .frame(width: 200, height: 60, alignment: .leading)
                            
                            Spacer()
                            Text("Parlay Bonus")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Points: \(abs(parlay.totalPoints))")
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 100, height: 2)
                                .foregroundStyle(.secondary)
                        }
                        .bold()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(24)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            
            VStack {
                Image(systemName: parlay.result == .win ? "checkmark.circle" : parlay.result == .loss ? "xmark.circle" : "hourglass.circle")
                    .font(.largeTitle.bold())
                    .foregroundColor(parlay.result == .win ? .bean : parlay.result == .loss ? .redd : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
            
            if deleteActive {
                HStack(spacing: 12) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .font(.title2.bold())
                        .bold()
                        .fontDesign(.rounded)
                        .padding(.bottom, 12)
                        .onTapGesture {
                            withAnimation {
                                deleteActive.toggle()
                                Task {
                                    let _ = try await ParlayViewModel().deleteParlay(parlayID: parlay.id.uuidString)
                                }
                            }
                        }
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.bean)
                        .font(.title2.bold())
                        .fontDesign(.rounded)
                        .padding(.bottom, 12)
                        .onTapGesture {
                            withAnimation {
                                deleteActive.toggle()
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 12)
                .matchedGeometryEffect(id: "trash", in: trash)
            } else {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .font(.title2.bold())
                    .fontDesign(.rounded)
                    .padding(.bottom, 12)
                    .onTapGesture {
                        withAnimation {
                            deleteActive.toggle()
                        }
                    }
                    .matchedGeometryEffect(id: "trash", in: trash)
            }
        }
        .frame(height: 160)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
        .task {
            formattedBets = parlay.betString?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces))
            } ?? []
            legs = formattedBets.count
        }
    }
}
