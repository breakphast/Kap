//
//  BetViews.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct PlacedBetView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var deleteActive = false
    @State private var maxBets = 0
    @Namespace var trash
    let bet: Bet
    @Binding var bets: [Bet]
    let week: Int
    
    func pointsColor(for result: BetResult) -> Color {
        switch result {
        case .win:
            return Color("bean")
        case .loss:
            return Color("redd")
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
                            Text("(\(bet.game.dayType ?? "") \(bets.filter({ $0.game.dayType ?? "" == bet.betOption.game.dayType && bet.week == week && $0.game.date == bet.game.date }).count)/\(maxBets))")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    
                    HStack {
                        Text("\(bet.game.awayTeam) @ \(bet.game.homeTeam)")
                        Spacer()
                        Text(convertDateForBetCard(bet.game.date))
                    }
                    .font(.caption2.bold())
                    .lineLimit(1)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Text("Points:")
                                .font(.headline.bold())
                            Text("\(bet.result != .pending ? bet.points! < 1 ? "-" : "+" : "")\(abs(bet.result == .push ? 0 : bet.points!).twoDecimalString)")
                                .font(.title2.bold())
                                .foregroundStyle(pointsColor(for: bet.result ?? .pending))
                        }
                        Spacer()
                        if bet.result != .pending {
                            Image(systemName: bet.result == .win ? "checkmark.circle" : "xmark.circle")
                                .font(.title3.bold())
                                .foregroundColor(bet.result == .win ? Color("bean") : bet.result == .loss ? Color("redd") : .secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            }
            .fontDesign(.rounded)
            .multilineTextAlignment(.leading)
            
            if Date() < bet.game.date {
                if deleteActive {
                    HStack(spacing: 14) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color("redd"))
                            .font(.title.bold())
                            .fontDesign(.rounded)
                            .padding(.bottom, 12)
                            .onTapGesture {
                                withAnimation {
                                    deleteActive.toggle()
                                }
                            }
                        
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("bean"))
                            .font(.title.bold())
                            .fontDesign(.rounded)
                            .padding(.bottom, 12)
                            .onTapGesture {
                                withAnimation {
                                    deleteActive.toggle()
                                    Task {
                                        let _ = try await BetViewModel().deleteBet(betID: bet.id)
                                        bets.removeAll(where: { $0.id == bet.id })
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
        }
        .frame(height: 150)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .task {
            switch DayType(rawValue: bet.game.dayType ?? "") {
            case .tnf, .mnf, .snf:
                self.maxBets = 1
            default:
                self.maxBets = 7
            }
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

struct PlacedParlayView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State var deleteActive = false
    @Namespace var trash
    let parlay: Parlay
    
    @State private var formattedBets = [String]()
    @State private var legs: Int = 0
    
    func pointsColor(for result: BetResult) -> Color {
        switch result {
        case .win:
            return Color("bean")
        case .loss:
            return Color("redd")
        case .push, .pending:
            return .primary
        }
    }
    
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
                            HStack(spacing: 4) {
                                Text("Points:")
                                    .font(.headline.bold())
                                Text("\(parlay.result == .loss ? "-" : "+")\(abs(parlay.totalPoints).twoDecimalString)")
                                    .font(.title3.bold())
                                    .foregroundStyle(pointsColor(for: parlay.result))
                            }
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
                    .foregroundColor(parlay.result == .win ? Color("bean") : parlay.result == .loss ? Color("redd") : .secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(24)
            
            if parlay.bets.filter({ Date() > $0.game.date }).count == 0 {
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
                                        let _ = try await ParlayViewModel().deleteParlay(parlayID: parlay.id)
                                    }
                                }
                            }
                        
                        Image(systemName: "checkmark")
                            .foregroundColor(Color("bean"))
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
                } else if parlay.result == .pending {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .font(.title2.bold())
                        .fontDesign(.rounded)
                        .onTapGesture {
                            withAnimation {
                                deleteActive.toggle()
                            }
                        }
                        .matchedGeometryEffect(id: "trash", in: trash)
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(height: 160)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .task {
            formattedBets = parlay.betString?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces))
            } ?? []
            legs = formattedBets.count
        }
    }
}
