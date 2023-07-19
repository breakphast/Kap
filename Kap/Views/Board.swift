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
                if viewModel.selectedBets.count > 0 {
                    NavigationLink(destination: SelectedBetsView()) {
                        ZStack {
                            Color("onyxLightish")
                            HStack(spacing: 8) {
                                Text("Betslip")
                                if viewModel.selectedBets.count > 1 {
                                    Image(systemName: "gift.fill")
                                }
                            }
                            .font(.title3.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.yellow)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        }
                        .frame(height: 60)
                        .cornerRadius(20)
                        .padding(.horizontal, 40)
                        .shadow(radius: 10)
                    }
                    .zIndex(100)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if viewModel.selectedBets.count > 1 && viewModel.parlays.count < 1 {
                                    viewModel.activeParlays = []
                                    let parlay = BetService().makeParlay(for: viewModel.selectedBets, player: viewModel.players[0])
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
                
                ScrollView(showsIndicators: false) {
                    GameListingView(players: viewModel.players)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Board")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                            ToolbarItem(placement: .topBarLeading) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .onTapGesture {
                                        dismiss()
                                    }
                            }
                        }
                        .task {
                            if viewModel.players.isEmpty {
                                let _ = await viewModel.getLeaderboardData()
                            }
                        }
                }
                .padding(.top, 24)
                .fontDesign(.rounded)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.games, id: \.id) { game in
                GameRow(game: game, players: players)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
}

struct GameRow: View {
    var game: Game
    var players: [Player]
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @Environment(\.viewModel) private var viewModel
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Text(game.awayTeam)
                Text("@")
                Text(game.homeTeam)
            }
            .font(.subheadline.bold())
            .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
            
            Spacer()
            
            let bets = AppDataViewModel().generateRandomBets(from: game)
            
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
            .frame(maxWidth: UIScreen.main.bounds.width / 2)
        }
        .padding(.bottom, 20)
    }
}
