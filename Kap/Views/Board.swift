//
//  Board.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI

struct Board: View {
    @State private var games = [Game]()
    @State private var players: [Player] = []
    let viewModel = AppDataViewModel()
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.games, id: \.id) { game in
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(game.awayTeam)
                                    Text("@")
                                    Text(game.homeTeam)
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
                                
                                Spacer()
                                
                                let options = [0, 2, 4, 1, 3, 5].compactMap { index in
                                    game.betOptions.indices.contains(index) ? game.betOptions[index] : nil
                                }
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(options, id: \.id) { betOption in
                                        CustomButton(betOption: betOption.betString) {
                                            BetService().makeBet(for: game, betOption: betOption, player: players[3])
                                        }
                                    }
                                }
                                .frame(maxWidth: UIScreen.main.bounds.width / 2)
                            }
                            .padding(.bottom, 20)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Leaderboard")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                    }
                    .task {
                        self.players = await viewModel.getLeaderboardData()
                        BetService().makeBet(for: viewModel.games[0], betOption: viewModel.games[0].betOptions[0], player: players[0])
                        BetService().makeParlay(for: viewModel.games, player: players[1])
                    }
                }
            }
            .fontDesign(.rounded)
        }
    }
}

#Preview {
    Board()
}
