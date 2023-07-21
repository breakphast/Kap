//
//  Board.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI

struct Board: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @Environment(\.viewModel) private var viewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GameListingView(players: viewModel.players)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Board")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                if viewModel.selectedBets.count > 1 && calculateParlayOdds(bets: viewModel.selectedBets) > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "gift.fill")
                                        Text("+\(calculateParlayOdds(bets: viewModel.selectedBets))".replacingOccurrences(of: ",", with: ""))
                                            .font(.caption2)
                                            .offset(y: -4)
                                    }
                                    .fontDesign(.rounded)
                                    .fontWeight(.black)
                                    .foregroundStyle(Color("lion"))
                                }
                            }
                            
                            ToolbarItem(placement: .topBarLeading) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .onTapGesture {
                                        dismiss()
                                    }
                            }
                        }
                    Rectangle()
                        .frame(height: 40)
                        .foregroundStyle(.clear)
                }
                .padding(.top, 12)
                .fontDesign(.rounded)
                
                if viewModel.selectedBets.count > 0 {
                    Spacer()
                    NavigationLink(destination: Betslip()) {
                        ZStack {
                            Color("onyxLightish")
                            
                            Text("Betslip")
                            .font(.title.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.lion)
                        }
                        .frame(height: 60)
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                        .shadow(radius: 10)
                    }
                    .zIndex(100)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if viewModel.selectedBets.count > 1 {
                                    viewModel.activeParlays = []
                                    let parlay = BetService().makeParlay(for: viewModel.selectedBets)
                                    
                                    if parlay.totalOdds >= 400 {
                                        viewModel.activeParlays.append(parlay)
                                        viewModel.activeButtons = [UUID]()
                                    }
                                } else {
                                    viewModel.activeParlays = []
                                }
                            }
                    )
                }
            }
        }
    }
}

#Preview {
    Board()
}

struct GameListingView: View {
    @Environment(\.viewModel) private var viewModel
    var players: [Player]
    
    private var thursdayNightGame: [Game] {
        Array(viewModel.games.prefix(1))
    }
    
    private var sundayGames: [Game] {
        Array(viewModel.games.dropFirst().dropLast(2))
    }
    
    private var sundayNightGame: [Game] {
        Array(viewModel.games.suffix(2).prefix(1))
    }
    
    private var mondayNightGame: [Game] {
        Array(viewModel.games.suffix(1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionView(title: "Thursday Night Football", games: thursdayNightGame)
            SectionView(title: "Sunday Afternoon", games: sundayGames)
            SectionView(title: "Sunday Night Football", games: sundayNightGame)
            SectionView(title: "Monday Night Football", games: mondayNightGame)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
}

struct SectionView: View {
    var title: String
    var games: [Game]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.lion)
                .padding(.bottom)
            
            ForEach(games, id: \.id) { game in
                GameRow(game: game)
            }
        }
    }
}


struct GameRow: View {
    var game: Game
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @Environment(\.viewModel) private var viewModel
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 10) {
                Text(nflTeams[game.awayTeam] ?? "")
                Text("@")
                Text(nflTeams[game.homeTeam] ?? "")
            }
            .font(.headline.bold())
            .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
            
            Spacer()
            
            let bets = AppDataViewModel().generateBetsForGame(game)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(bets, id: \.id) { bet in
                    CustomButton(bet: bet, buttonText: bet.betOption.betString) {
                        withAnimation {
                            if viewModel.selectedBets.contains(where: { $0.id == bet.id }) {
                                viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                            } else {
                                viewModel.selectedBets.append(bet)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width / 1.75)
        }
        .padding(.bottom, 20)
    }
}
