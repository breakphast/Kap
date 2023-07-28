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
    
    @State private var bets: [Bet] = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.onyx.ignoresSafeArea()
            
            Text("Week \(viewModel.currentWeek)")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)
            
            TabView {
                VStack {
                    if bets.filter({ $0.result == .pending }).isEmpty {
                        Text("No active bets")
                            .foregroundColor(.white)
                            .font(.largeTitle.bold())
                    } else {
                        Text("Active Bets")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.lion)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 20) {
                                ForEach(bets.filter({ $0.result == .pending }), id: \.id) { bet in
                                    PlacedBetView(bet: bet, bets: $bets)
                                }
                                ForEach(viewModel.parlays, id: \.id) { parlay in
                                    PlacedParlayView(parlay: parlay)
                                }
                                Rectangle()
                                    .frame(height: 40)
                                    .foregroundStyle(.clear)
                            }
                            .padding(.top, 20)
                        }
                    }
                }
                .padding(.top, 40)
                .tabItem { Text("Active Bets") }
                
                VStack {
                    if bets.filter({ $0.result != .pending }).isEmpty && viewModel.parlays.filter({ $0.result != .pending }).isEmpty {
                        Text("No settled bets")
                            .foregroundColor(.white)
                            .font(.largeTitle.bold())
                    } else {
                        Text("Settled Bets")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .foregroundStyle(.lion)
                        
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 20) {
                                ForEach(bets.filter({ $0.result != .pending }), id: \.id) { bet in
                                    PlacedBetView(bet: bet, bets: $bets)
                                }
                                ForEach(viewModel.parlays, id: \.id) { parlay in
                                    PlacedParlayView(parlay: parlay)
                                }
                                Rectangle()
                                    .frame(height: 40)
                                    .foregroundStyle(.clear)
                            }
                            .padding(.top, 20)
                        }
                    }
                }
                .padding(.top, 40)
                .tabItem { Text("Settled Bets") }
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
                
                ToolbarItem(placement: .principal) {
                    Text("My Bets")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
            }
        }
        .fontDesign(.rounded)
        .onChange(of: bets.count, { _, _ in
            Task {
                do {
                    let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
                    bets = fetchedBets.filter({ $0.playerID == viewModel.activeUser?.id })
                    bets = bets.filter({ $0.week == viewModel.currentWeek })
                } catch {
                    print("Error fetching bets: \(error)")
                }
            }
        })
        .task {
            do {
                let fetchedBets = try await BetViewModel().fetchBets(games: viewModel.games)
                bets = fetchedBets.filter({ $0.playerID == viewModel.activeUser?.id })
                bets = bets.filter({ $0.week == viewModel.currentWeek })
            } catch {
                print("Error fetching bets: \(error)")
            }
        }

    }
}

#Preview {
    MyBets()
}

struct PlacedBetView: View {
    @Environment(\.viewModel) private var viewModel
    @State var deleteActive = false
    @Namespace var trash
    let bet: Bet
    @Binding var bets: [Bet]
    
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
                        RoundedRectangle(cornerRadius: 1)
                            .frame(width: 80, height: 2)
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
                HStack(spacing: 12) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .font(.headline.bold())
                        .fontDesign(.rounded)
                        .padding(.bottom, 12)
                        .onTapGesture {
                            withAnimation {
                                deleteActive.toggle()
                            }
                        }
                    
                    Image(systemName: "checkmark")
                        .foregroundColor(.bean)
                        .font(.headline.bold())
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
                    .fontWeight(.bold)
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
                            Text("Points: \(abs(parlay.totalPoints))")
                            RoundedRectangle(cornerRadius: 1)
                                .frame(width: 80, height: 2)
                                .foregroundStyle(.secondary)
                        }
                        .bold()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
//                .padding([.bottom, .trailing], 12)
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
            .padding(.trailing, 24)
            .padding(.bottom, 12)
            
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
                .padding(.bottom, 8)
                .matchedGeometryEffect(id: "trash", in: trash)
            } else {
                Image(systemName: "trash")
                    .foregroundColor(.onyxLightish)
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
        .frame(height: 180)
        .cornerRadius(20)
        .padding(.horizontal, 20)
        .shadow(radius: 10)
    }
}


let nflTeams = [
    "Miami Dolphins": "MIA Dolphins",
    "New England Patriots": "NE Patriots",
    "Buffalo Bills": "BUF Bills",
    "New York Jets": "NYJ Jets",
    "Pittsburgh Steelers": "PIT Steelers",
    "Baltimore Ravens": "BAL Ravens",
    "Cleveland Browns": "CLE Browns",
    "Cincinnati Bengals": "CIN Bengals",
    "Tennessee Titans": "TEN Titans",
    "Indianapolis Colts": "IND Colts",
    "Houston Texans": "HOU Texans",
    "Jacksonville Jaguars": "JAX Jaguars",
    "Kansas City Chiefs": "KC Chiefs",
    "Las Vegas Raiders": "LV Raiders",
    "Denver Broncos": "DEN Broncos",
    "Los Angeles Chargers": "LAC Chargers",
    "Dallas Cowboys": "DAL Cowboys",
    "Philadelphia Eagles": "PHI Eagles",
    "New York Giants": "NYG Giants",
    "Washington Football Team": "WAS Football Team",
    "Green Bay Packers": "GB Packers",
    "Chicago Bears": "CHI Bears",
    "Minnesota Vikings": "MIN Vikings",
    "Detroit Lions": "DET Lions",
    "San Francisco 49ers": "SF 49ers",
    "Seattle Seahawks": "SEA Seahawks",
    "Los Angeles Rams": "LA Rams",
    "Arizona Cardinals": "ARI Cardinals",
    "Atlanta Falcons": "ATL Falcons",
    "New Orleans Saints": "NO Saints",
    "Tampa Bay Buccaneers": "TB Buccaneers",
    "Carolina Panthers": "CAR Panthers"
]
