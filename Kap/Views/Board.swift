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
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @Environment(\.viewModel) private var viewModel
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                if viewModel.activeButtons.count > 0 {
                    Button {
                        
                    } label: {
                        ZStack {
                            Color("onyxLightish")
                            HStack(spacing: 8) {
                                Text("Betslip")
                                
                                Image(systemName: "arrowshape.right.fill")
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
                }
                
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
                                
                                let options = [1, 3, 4, 0, 2, 5].compactMap { index in
                                    game.betOptions.indices.contains(index) ? game.betOptions[index] : nil
                                }
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(options, id: \.id) { betOption in
                                        CustomButton(betOption: betOption, buttonText: betOption.betString, viewModel: viewModel) {
                                            withAnimation {
                                                let bet = BetService().makeBet(for: game, betOption: betOption, player: players[3])
                                                viewModel.bets.append(bet)
                                            }
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
                            Text("Board")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                    }
                    .task {
                        if self.players.isEmpty {
                            self.players = await viewModel.getLeaderboardData()
                        }
                    }
                }
                .padding(.top, 24)
            }
            .fontDesign(.rounded)
        }
    }
}

#Preview {
    Board()
}
