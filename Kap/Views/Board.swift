//
//  Board.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI
import CoreData
import FirebaseFirestore
import Firebase
import FirebaseFirestoreSwift

struct Board: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @EnvironmentObject var leaderboardViewModel: LeaderboardViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let db = Firestore.firestore()
    
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
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GameListingView(allGameModels: homeViewModel.weekGames)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                HStack {
                                    Text(leagueViewModel.activeLeague?.name ?? "Loch Sports")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                    
                                    Image(systemName: "arrow.left.arrow.right.square")
                                        .font(.caption.bold())
                                        .foregroundStyle(.lion)
                                }
                                .onTapGesture {
                                    leagueViewModel.activeLeague = nil
                                }
                            }
                            #if DEBUG
                            ToolbarItem(placement: .automatic) {
                                Button("UPDATE SCORES") {
                                    Task {
                                        try await homeViewModel.personalRefresh(in: viewContext, games: Array(allGameModels), bets: Array(allBetModels), parlays: Array(allParlayModels), leagueCode: homeViewModel.activeleagueCode ?? "", userID: authViewModel.currentUser?.id ?? "")
                                        await leaderboardViewModel.generateWeeklyUserPoints(users: homeViewModel.users, bets: homeViewModel.leagueBets.filter({$0.week == homeViewModel.currentWeek}), parlays: homeViewModel.leagueParlays.filter({$0.week == homeViewModel.currentWeek}), games: Array(allGameModels), week: homeViewModel.currentWeek, leagueCode: homeViewModel.activeleagueCode ?? "", currentWeek: homeViewModel.currentWeek)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .foregroundStyle(.black)
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("UPDATE ODDS") {
                                    Task {
                                        try await homeViewModel.updateOdds(context: viewContext)
                                    }                                }
                                .buttonStyle(.borderedProminent)
                                .foregroundStyle(.black)
                            }
                            #endif
                            ToolbarItem(placement: .topBarTrailing) {
                                if homeViewModel.selectedBets.count > 2 && calculateParlayOdds(bets: homeViewModel.selectedBets) >= 400 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "gift.fill")
                                        Text("+\(calculateParlayOdds(bets: homeViewModel.selectedBets))".replacingOccurrences(of: ",", with: ""))
                                            .font(.caption2)
                                            .offset(y: -4)
                                    }
                                    .fontDesign(.rounded)
                                    .fontWeight(.black)
                                    .foregroundStyle(Color("lion"))
                                }
                            }
                        }
                    Rectangle()
                        .frame(height: 20)
                        .foregroundStyle(.clear)
                }
                .fontDesign(.rounded)
                .refreshable {
                    Task {
                        do {
                            if let activeleagueCode = homeViewModel.activeleagueCode, let userID = authViewModel.currentUser?.id {
                                try await homeViewModel.pedestrianRefresh(in: viewContext, games: Array(allGameModels), bets: Array(allBetModels), parlays: Array(allParlayModels), leagueCode: activeleagueCode, userID: userID)
                            }
                        } catch {
                            
                        }
                    }
                }
                
                if homeViewModel.selectedBets.count > 0 {
                    Spacer()
                    NavigationLink(destination: Betslip(parlay: $homeViewModel.activeParlay)) {
                        ZStack {
                            Color("lion")
                            
                            Text("Betslip")
                                .font(.title.bold())
                                .fontDesign(.rounded)
                                .foregroundStyle(Color("oW"))
                        }
                        .frame(height: 60)
                        .clipShape(TopRoundedRectangle(radius: 12))
                        .shadow(radius: 10)
                    }
                    .zIndex(100)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if homeViewModel.selectedBets.count > 1 {
                                    homeViewModel.activeParlay = nil
                                    let parlay = ParlayViewModel().makeParlay(for: homeViewModel.selectedBets, playerID: authViewModel.currentUser?.id ?? "", week: homeViewModel.currentWeek, leagueCode: homeViewModel.activeleagueCode ?? "")
                                    if parlay.totalOdds >= 400 && parlay.bets.count >= 3 {
                                        homeViewModel.activeParlay = parlay
                                    }
                                } else {
                                    homeViewModel.activeParlay = nil
                                }
                            }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                //                deleteAllData(ofEntity: "GameModel") { result in }
                //                deleteAllData(ofEntity: "BetOptionModel") { result in }
                //                deleteAllData(ofEntity: "Counter") { result in }
                //                deleteAllData(ofEntity: "BetModel") { result in }
                //                Utility.deleteAllData(ofEntity: "ParlayModel", in: viewContext) { result in }
            }
        }
    }
}

struct GameListingView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    let allGameModels: [GameModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionView(title: "NFL", games: allGameModels.sorted(by: {$0.date < $1.date}), first: true)
        }
        .padding()
    }
}

struct SectionView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    var title: String
    var games: [GameModel]
    var first: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if first == true {
                    Text(title)
                        .font(.caption.bold())
                        .foregroundColor(Color("oW"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("lion"))
                        .cornerRadius(4)
                        .padding(.bottom)
                }
                
                Spacer()
                
                if first != nil {
                    HStack(spacing: 10) {
                        Text("Spread")
                            .frame(maxWidth: UIScreen.main.bounds.width / (1.75 * 3), alignment: .center)
                        Text("ML")
                            .frame(maxWidth: UIScreen.main.bounds.width / (1.75 * 3), alignment: .center)
                        Text("Totals")
                            .frame(maxWidth: UIScreen.main.bounds.width / (1.75 * 3), alignment: .center)
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width / 1.75)
                    .font(.caption.bold())
                    .padding(.bottom)
                }
            }
            
            ForEach(games, id: \.id) { game in
                if Date() < game.date {
                    GameRow(game: game)
                }
            }
        }
    }
}

struct GameRow: View {
    var game: GameModel
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var newGame: GameModel?
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: GameModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GameModel.date, ascending: true)
        ]
    ) var allGameModels: FetchedResults<GameModel>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(convertDateToDesiredFormat(game.date))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image("\(nflLogos[game.awayTeam ?? ""] ?? "")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                        Text(nflTeams[game.awayTeam ?? ""] ?? "")
                    }
                    Text("@")
                    HStack {
                        Image("\(nflLogos[game.homeTeam ?? ""] ?? "")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                        Text(nflTeams[game.homeTeam ?? ""] ?? "")
                    }
                }
                .font(.caption.bold())
                .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
                .lineLimit(2)
                
                Spacer()
                
                let bets = BetViewModel().generateBetsForGame(game)
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(bets, id: \.id) { bet in
                        CustomButton(bet: bet, buttonText: bet.betOptionString) {
                            withAnimation {
                                bet.week = homeViewModel.currentWeek
                                if homeViewModel.selectedBets.contains(where: { $0.id == bet.id }) {
                                    homeViewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                                } else {
                                    homeViewModel.selectedBets.append(bet)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width / 1.75)
            }
        }
    }
}
