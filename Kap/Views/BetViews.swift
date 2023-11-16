//
//  BetViews.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI
import FirebaseFirestoreSwift
import FirebaseFirestore
import Firebase
import CoreData

struct BetView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @State var isValid = false
    @State var isPlaced = false
    @Environment(\.dismiss) var dismiss
    let bet: Bet
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: GameModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GameModel.date, ascending: true)
        ]
    ) var allGameModels: FetchedResults<GameModel>
    
    @FetchRequest(
        entity: BetModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BetModel.timestamp, ascending: true)
        ]
    ) var allBetModels: FetchedResults<BetModel>
    
    @FetchRequest(
        entity: ParlayModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ParlayModel.timestamp, ascending: true)
        ]
    ) var allParlayModels: FetchedResults<ParlayModel>
    
    var body: some View {
        ZStack(alignment: .center) {
            Color(.onyxLightish)
            if isPlaced {
                Label("Bet placed!", systemImage: "checkmark")
                    .padding()
                    .bold()
            } else {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 8) {
                        teamAndType
                        pointsAndButtons
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
                .fontDesign(.rounded)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            }
        }
        .cornerRadius(18)
        .padding(.horizontal, 12)
        .shadow(radius: 10)
        .task {
            isValid = homeViewModel.userBets.filter({ $0.week == homeViewModel.currentWeek }).count < 10 && homeViewModel.userBets.filter({ $0.game.id == bet.game.id }).isEmpty
        }
        .onChange(of: homeViewModel.userBets.count) { newValue in
            isValid = homeViewModel.userBets.filter({ $0.week == homeViewModel.currentWeek }).count < 10 && homeViewModel.userBets.filter({ $0.game.id == bet.game.id }).isEmpty
        }
    }
    
    var pointsAndButtons: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                Text("Points: \(String(format: "%.1f", bet.points ?? 0))")
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundStyle(.lion)
                Spacer()
                HStack(spacing: 4) {
                    Text(Utility.dayOfWeek(from: bet.game.date ?? Date()))
                    Text(Utility.formattedTime(from: bet.game.date ?? Date()))
                }
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.oW2)
            }
            
            buttons
                .frame(maxWidth: .infinity, alignment: .bottom)
        }
    }
    
    var teamAndType: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(bet.type == .over || bet.type == .under ? "\(bet.game.awayTeam ?? "") @ \(bet.game.homeTeam ?? "")" : bet.selectedTeam ?? "")
                    .font(bet.type == .over || bet.type == .under ? .caption2 : .headline)
                    .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .leading)
                
                Spacer()
                
                Text("\(bet.odds > 0 ? "+" : "")\(bet.odds)".replacingOccurrences(of: ",", with: ""))
            }
            .bold()
            
            HStack(alignment: .top) {
                Text(betText)
                    .font(.subheadline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .fontWidth(.expanded)
                    .autocapitalization(.allCharacters)
                    .foregroundStyle(.oW2)
                Spacer()
                Text("NFL")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("oW"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color("lion"))
                    .cornerRadius(4)
            }
        }
    }
    
    var buttons: some View {
        HStack {
            Button {
                Task {
                    guard let betOptionsSet = bet.game.betOptions as? Set<BetOptionModel> else {
                        print("Failed to retrieve bet options.")
                        return
                    }

                    let betOptionsArray = Array(betOptionsSet)
                    guard let betOption = betOptionsArray.first(where: { $0.id == bet.betOption }) else {
                        print("Bet option not found.")
                        return
                    }
                    
                    if let placedBet = BetViewModel().makeBet(for: bet.game, betOption: betOption.id ?? "", playerID: authViewModel.currentUser?.id ?? "", week: homeViewModel.currentWeek, leagueCode: homeViewModel.activeleagueCode ?? "") {
                        if !homeViewModel.userBets.contains(where: { $0.game.documentID == placedBet.game.documentID && $0.leagueCode == homeViewModel.activeleagueCode! }) {
                            try await BetViewModel().addBet(bet: placedBet, playerID: authViewModel.currentUser?.id ?? "", in: viewContext)
                            homeViewModel.leagueBets = Array(allBetModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                            homeViewModel.userBets = homeViewModel.leagueBets.filter({$0.playerID == authViewModel.currentUser?.id})
                                                    
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
                    } else {
                        return
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
                .frame(width: UIScreen.main.bounds.width * 0.33, height: 44)
                .cornerRadius(12)
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
                .frame(width: UIScreen.main.bounds.width * 0.33, height: 44)
                .cornerRadius(12)
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
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: ParlayModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ParlayModel.timestamp, ascending: true)
        ]
    ) var allParlayModels: FetchedResults<ParlayModel>

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
                            Text("Points: \(String(format: "%.1f", parlay.totalPoints))")
                                .font(.title3)
                                .fontWeight(.heavy)
                                .foregroundStyle(.lion)
                            
                            Spacer()
                            
                            buttons
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
        }
        .cornerRadius(18)
        .padding(.horizontal, 12)
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
                try await ParlayViewModel().addParlay(parlay: placedParlay, in: viewContext)
                homeViewModel.leagueParlays = Array(allParlayModels).filter({$0.leagueCode == homeViewModel.activeleagueCode})
                homeViewModel.userParlays = homeViewModel.leagueParlays.filter({$0.playerID == authViewModel.currentUser?.id})
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
            .frame(width: 100, height: 44)
            .cornerRadius(12)
            .shadow(radius: 12)
        }
        .zIndex(100)
        .disabled(!isValid)
    }
}

struct PlacedBetView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @State var deleteActive = false
    @State private var maxBets = 0
    @Namespace var trash
    let bet: BetModel
    let week: Int16
    let live: Bool
    let hideMenu: Bool
    let db = Firestore.firestore()
    
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
    
    var teamAndType: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(bet.type == "Over" || bet.type == "Under" ? "\(bet.game.awayTeam ?? "") @ \(bet.game.homeTeam ?? "")" : bet.selectedTeam ?? "")
                    .font(bet.type == "Over" || bet.type == "Under" ? .caption2 : .headline)
                    .frame(maxWidth: UIScreen.main.bounds.width / 1.5, alignment: .leading)
                
                Spacer()
                
                Text("\(bet.odds > 0 ? "+" : "")\(bet.odds)".replacingOccurrences(of: ",", with: ""))
            }
            .bold()
            
            HStack(alignment: .top) {
                Text(betText)
                    .font(.subheadline)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .fontWidth(.expanded)
                    .autocapitalization(.allCharacters)
                    .foregroundStyle(.oW2)
                Spacer()
                Text("NFL")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("oW"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color("lion"))
                    .cornerRadius(4)
            }
        }
    }

    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(.onyxLightish)
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 12) {
                    teamAndType
                    
                    HStack {
                        Text("\(bet.game.awayTeam ?? "") @ \(bet.game.homeTeam ?? "")")
                        Spacer()
                        HStack(spacing: 4) {
                            Text(Utility.dayOfWeek(from: bet.game.date ?? Date()))
                            Text(Utility.formattedTime(from: bet.game.date ?? Date()))
                        }
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.oW2)
                    }
                    .font(.caption2.bold())
                    .lineLimit(1)
                    
                    HStack {
                        Text("\(bet.result != "Pending" ? bet.points < 0 ? "-" : "+" : "")\(abs(bet.result == "Push" ? 0 : bet.points).oneDecimalString)")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundStyle(pointsColor(for: BetResult(rawValue: bet.result) ?? .pending))
                        Spacer()
                        
                        if bet.result != "Pending" {
                            HStack(spacing: 4) {
                                Image(systemName: bet.result == "Win" ? "checkmark.circle" : "xmark.circle")
                                Text(bet.result).autocapitalization(.allCharacters)
                            }
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(bet.result == "Win" ? Color("bean") : bet.result == "Loss" ? Color("redd") : .oW2)
                        } else if !hideMenu {
                            menu
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(18)
            }
            .fontDesign(.rounded)
            .multilineTextAlignment(.leading)
        }
        .frame(height: 125)
        .cornerRadius(15)
    }
    
    private var menu: some View {
        Menu {
            Button {
                withAnimation {
                    deleteActive.toggle()
                    Task {
                        try await BetViewModel().deleteBet(betID: bet.id)
                        BetViewModel().recreateBet(bet: bet, games: homeViewModel.allGames, playerID: bet.playerID, in: viewContext)
                        BetViewModel().deleteBetModel(in: viewContext, id: bet.id)
                        homeViewModel.allBets.removeAll(where: { $0.id == bet.id })
                        homeViewModel.userBets.removeAll(where: { $0.id == bet.id })
                        homeViewModel.leagueBets.removeAll(where: { $0.id == bet.id })
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
        if bet.type == "Over" || bet.type == "Under" {
            return bet.type + " " + (bet.type == "Over" ? String(bet.game.over) : String(bet.game.under))
        } else if bet.type == "Spread" {
            return "Spread " + bet.betString
        } else {
            return bet.type
        }
    }
}

struct PlacedParlayView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State var deleteActive = false
    @Namespace var trash
    let parlay: ParlayModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var formattedBets = [String]()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color("onyxLightish")
            HStack(spacing: 8) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .center) {
                            Text("\(Array(parlay.bets).count) Leg Parlay")
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
                                Text("\(parlay.totalPoints < 0 ? "-" : "+")\(abs(parlay.totalPoints).oneDecimalString)")
                                    .font(.title3)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(pointsColor(for: BetResult(rawValue: parlay.result) ?? .pending))
                            }
                            Spacer()
                            
                            if parlay.bets.allObjects is [BetModel] && parlay.result == "Pending" {
                                menu
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: parlay.result == "Win" ? "checkmark.circle" : "xmark.circle")
                                    Text(parlay.result).autocapitalization(.allCharacters)
                                }
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(parlay.result == "Win" ? Color("bean") : parlay.result == "Loss" ? Color("redd") : .oW2)
                            }
                        }
                        .bold()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(18)
            }
            .fontDesign(.rounded)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            
            if let betsArray = parlay.bets.allObjects as? [Bet],
               betsArray.filter({ Date() > ($0.game.date ?? Date()) }).isEmpty {
                if deleteActive {
                    
                }
            }
        }
        .cornerRadius(18)
        .task {
            formattedBets = parlay.betString?.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces))
            } ?? []
        }
    }
    
    private var menu: some View {
        Menu {
            Button {
                withAnimation {
                    deleteActive.toggle()
                    Task {
                        try await ParlayViewModel().deleteParlay(parlayID: parlay.id)
                        ParlayViewModel().recreateParlay(parlay: parlay, games: homeViewModel.allGames, playerID: parlay.playerID, in: viewContext)
                        ParlayViewModel().deleteParlayModel(in: viewContext, id: parlay.id)
                        
                        homeViewModel.allParlays.removeAll(where: { $0.id == parlay.id })
                        homeViewModel.userParlays.removeAll(where: { $0.id == parlay.id })
                        homeViewModel.leagueParlays.removeAll(where: { $0.id == parlay.id })
                        
                        homeViewModel.allBets.removeAll(where: {$0.id.contains(parlay.id)})
                        homeViewModel.userBets.removeAll(where: {$0.id.contains(parlay.id)})
                        homeViewModel.leagueBets.removeAll(where: {$0.id.contains(parlay.id)})
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
}

extension BetOption: Hashable {
    public static func == (lhs: BetOption, rhs: BetOption) -> Bool {
        return lhs.id == rhs.id // Assuming 'id' is a property of 'BetOption' and is unique.
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id) // This also assumes 'id' is a property of 'BetOption'.
    }
}
