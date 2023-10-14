//
//  BetViews.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI

struct BetView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @State var isValid = false
    @State var isPlaced = false
    @Environment(\.dismiss) var dismiss
    let bet: Bet
    
    private func fetchData() async {
        do {
            let activeleagueCode = homeViewModel.activeleagueCode ?? ""
            let currentWeek = homeViewModel.currentWeek
            let currentUserID = authViewModel.currentUser?.id
            
            let bets = homeViewModel.allBets.filter {
                $0.playerID == currentUserID &&
                $0.leagueCode == activeleagueCode &&
                $0.week == currentWeek
            }
            
            isValid = bets.filter {
                $0.game.dayType! == bet.game.dayType! &&
                $0.week == currentWeek
            }.count < maxBets2 && !bets.contains { $0.game.id == bet.game.id }
            
            homeViewModel.allParlays = try await ParlayViewModel().fetchParlays(games: homeViewModel.allGames)
            homeViewModel.leagueParlays = homeViewModel.allParlays.filter({ $0.leagueCode == leagueViewModel.activeLeague?.code })
            homeViewModel.userParlays = homeViewModel.allParlays.filter({$0.playerID == authViewModel.currentUser?.id ?? "" && $0.leagueCode == leagueViewModel.activeLeague?.code})
        } catch {
            print("Error fetching. BetViews.")
        }
    }
    
    var maxBets2: Int {
        switch bet.game.dayType {
        case "SUN":
            7
        default:
            1
        }
    }
    
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
        .task {
            await fetchData()
        }
        .onChange(of: homeViewModel.userBets.count) { newValue in
            isValid = homeViewModel.leagueBets.filter({ $0.game.dayType! == bet.game.dayType! && $0.week == homeViewModel.currentWeek }).count < maxBets2 && homeViewModel.userBets.filter({ $0.game.id == bet.game.id }).isEmpty
        }
    }
    
    var pointsAndButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading) {
                Text("Points: \(String(format: "%.1f", bet.points ?? 0))")
                    .bold()
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 100, height: 2)
                    .foregroundStyle(.secondary)
            }
            
            buttons
                .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }
    
    var teamAndType: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bet.type == .over || bet.type == .under ? "\(bet.game.awayTeam) @ \(bet.game.homeTeam)" : bet.selectedTeam ?? "")
                    .font(bet.type == .over || bet.type == .under ? .caption2.bold() : .subheadline.bold())
                    .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .leading)
                
                Spacer()
                
                Text("\(bet.odds > 0 ? "+" : "")\(bet.odds)")
                    .font(.subheadline.bold())
            }
            .bold()
            
            HStack {
                Text(betText)
                    .font(.subheadline.bold())
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text("(\(bet.game.dayType ?? "") \(homeViewModel.userBets.filter({ $0.game.dayType ?? "" == bet.game.dayType ?? "" && $0.week == homeViewModel.currentWeek && $0.leagueCode == homeViewModel.activeleagueCode!}).count)/\(maxBets2))")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // place bet button
    var buttons: some View {
        HStack {
            Button {
                Task {
                    guard let betOption = bet.game.betOptions.first(where: { $0.id == bet.betOption }) else {
                        return
                    }
                    
                    let placedBet = BetViewModel().makeBet(for: bet.game, betOption: betOption.id, playerID: authViewModel.currentUser?.id ?? "", week: homeViewModel.currentWeek, leagueCode: homeViewModel.activeleagueCode ?? "")
                    
                    if !homeViewModel.userBets.contains(where: { $0.game.documentId == placedBet?.game.documentId && $0.leagueCode == homeViewModel.activeleagueCode! }) {
                        try await BetViewModel().addBet(bet: placedBet!, playerID: authViewModel.currentUser?.id ?? "")
                        homeViewModel.userBets.append(placedBet!)
                                                
                        isPlaced = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                homeViewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                                if homeViewModel.selectedBets.count == 0 {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            } label: {
                ZStack {
                    Color("lion")
                    Text("Place Bet")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(isValid ? Color("oW") : .gray)
                        .lineLimit(2)
                }
                .overlay {
                    Color("onyxLightish").opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
                }
                .frame(width: 100, height: 50)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
            .disabled(!isValid)
            
            Button {
                withAnimation {
                    homeViewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                    if homeViewModel.selectedBets.isEmpty {
                        dismiss()
                    }
                }
            } label: {
                ZStack {
                    Color("oW").opacity(0.8)
                    Text("Cancel Bet")
                        .font(.caption.bold())
                        .fontDesign(.rounded)
                        .foregroundStyle(Color("redd").opacity(0.8))
                        .lineLimit(2)
                }
                .frame(width: 100, height: 50)
                .cornerRadius(15)
                .shadow(radius: 10)
            }
            .zIndex(100)
        }
    }
    
    var betText: String {
        if bet.type == .over || bet.type == .under {
            return bet.type.rawValue + " " + (bet.type == .over ? String(bet.game.over) : String(bet.game.under))
        } else if bet.type == .spread {
            return "Spread " + bet.betString
        } else {
            return bet.type.rawValue
        }
    }
}

struct ParlayView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var isValid = false
    @Binding var parlays: [Parlay]
    let parlay: Parlay
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(parlay.bets.count) Leg Parlay")
                            Text("(Week \(parlay.week))")
                                .font(.caption2)
                            Spacer()
                            
                            Text("+\(parlay.totalOdds)".replacingOccurrences(of: ",", with: ""))
                        }
                        .bold()
                        
                        HStack {
                            Spacer()
                            Text("Parlay Bonus (\(parlays.count)/1)")
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
                                Text("Points: \(String(format: "%.1f", parlay.totalPoints))")
                                    .bold()
                                RoundedRectangle(cornerRadius: 1)
                                    .frame(width: 100, height: 2)
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
            isValid = parlays.count == 0 && parlay.totalOdds <= 1000
        }
        .onChange(of: parlays.count) { _ in
            isValid = parlays.count == 0 && parlay.totalOdds <= 1000
        }
    }
    
    var buttons: some View {
        Button {
            let placedParlay = ParlayViewModel().makeParlay(for: parlay.bets, playerID: authViewModel.currentUser?.id ?? "", week: homeViewModel.currentWeek, leagueCode: homeViewModel.activeleagueCode ?? "")
            Task {
                try await ParlayViewModel().addParlay(parlay: placedParlay)
                parlays.append(placedParlay)
                ParlayViewModel().updateParlayLeague(parlay: placedParlay, leagueCode: homeViewModel.activeleagueCode ?? "")
            }
            homeViewModel.activeParlay = nil
        } label: {
            ZStack {
                Color("onyxLightish")
                Text("Place Parlay")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(isValid ? Color("lion") : .white)
                    .lineLimit(2)
            }
            .overlay {
                Color("onyxLightish").opacity(isValid ? 0.0 : 0.7).ignoresSafeArea()
            }
            .frame(width: 100, height: 40)
            .cornerRadius(15)
            .shadow(radius: 10)
        }
        .zIndex(100)
        .disabled(!isValid)
    }
}

struct PlacedBetView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var deleteActive = false
    @State private var maxBets = 0
    @Namespace var trash
    let bet: Bet
//    @State var bets: [Bet]
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
                            Text("(\(bet.game.dayType!) \(homeViewModel.userBets.filter({ $0.game.dayType! == bet.game.dayType && $0.week == bet.week && $0.playerID == bet.playerID && $0.leagueCode == homeViewModel.activeleagueCode!}).count)/\(maxBets))")
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
                        
                        if Date() < bet.game.date && bet.result == .pending {
                            menu
                        }
                        
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
        }
        .frame(height: 125)
        .cornerRadius(18)
        .task {
            switch DayType(rawValue: bet.game.dayType ?? "") {
            case .tnf, .mnf, .snf:
                self.maxBets = 1
            default:
                self.maxBets = 7
            }
        }
    }
    
    private var menu: some View {
        Menu {
            Button {
                withAnimation {
                    deleteActive.toggle()
                    Task {
                        let _ = try await BetViewModel().deleteBet(betID: bet.id)
                        homeViewModel.userBets.removeAll(where: { $0.id == bet.id })
                    }
                }
            } label: {
                Label("Delete bet", systemImage: "trash")
            }
            Button("Cancel") {
                
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title.bold())
        }
        .zIndex(1000)
    }
    
    var betText: String {
        if bet.type == .over || bet.type == .under {
            return bet.type.rawValue + " " + (bet.type == .over ? String(bet.game.over) : String(bet.game.under))
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
                        HStack(alignment: .center) {
                            Text("\(legs) Leg Parlay")
                            Text("(Week \(parlay.week))")
                                .font(.caption2)
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
                        
                        HStack {
                            HStack(spacing: 4) {
                                Text("Points:")
                                    .font(.headline.bold())
                                Text("\(parlay.result == .loss ? "-" : "+")\(abs(parlay.totalPoints).twoDecimalString)")
                                    .font(.title3.bold())
                                    .foregroundStyle(pointsColor(for: parlay.result))
                            }
                            Spacer()
                            
                            if parlay.bets.contains(where: { Date() < $0.game.date && $0.result == .pending }) {
                                menu
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
            
            if parlay.bets.filter({ Date() > $0.game.date }).count == 0 {
                if deleteActive {
                    
                }
            }
        }
        .frame(height: 160)
        .cornerRadius(20)
        .task {
            formattedBets = parlay.betString?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces))
            } ?? []
            legs = formattedBets.count
        }
    }
    
    private var menu: some View {
        Menu {
            Button {
                withAnimation {
                    deleteActive.toggle()
                    Task {
                        let _ = try await ParlayViewModel().deleteParlay(parlayID: parlay.id)
                        homeViewModel.leagueParlays.removeAll(where: { $0.id == parlay.id })
                    }
                }
            } label: {
                Label("Delete parlay", systemImage: "trash")
            }
            Button("Cancel") {
                
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title.bold())
        }
        .zIndex(1000)
    }
}
