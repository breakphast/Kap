//
//  Board.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI

struct Board: View {
    @State private var players: [Player] = []
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
                                Image(systemName: viewModel.selectedBets.count > 1 ? "gift.fill" : "")
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
                                viewModel.activeParlays = []
                                let parlay = BetService().makeParlay(for: viewModel.selectedBets, player: players[0])
                                viewModel.activeParlays.append(parlay)
                                viewModel.activeButtons = [UUID]()
                            }
                    )
                }
                
                ScrollView(showsIndicators: false) {
                    GameListingView(players: players)
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
                            if self.players.isEmpty {
                                self.players = await viewModel.getLeaderboardData()
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
            
            let options = [1, 3, 4, 0, 2, 5].compactMap { index in
                game.betOptions.indices.contains(index) ? game.betOptions[index] : nil
            }
            
            let bets = AppDataViewModel().generateRandomBets(from: viewModel.games)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(bets.enumerated()), id: \.1.id) { i, bet in
                    CustomButton(bet: bet, buttonText: options[i].betString) {
                        withAnimation {
//                            let bet = BetService().makeBet(for: game, betOption: options[i])
//                            print(bet.betString)
                            if viewModel.selectedBets.contains(where: { $0.id == bet.id }) {
                                viewModel.selectedBets.removeAll(where: { $0.id == bet.id })
                            } else {
                                viewModel.selectedBets.append(bet)
                                print("---------")
                                print(bet.id)
                                print(viewModel.selectedBets[0].id)
                                print(bet.betString)
                                print(viewModel.selectedBets[0].betString)
                                
                            }
                            print("YO", bet.id)
                        }
                    }
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width / 2)
        }
        .padding(.bottom, 20)
    }
}
