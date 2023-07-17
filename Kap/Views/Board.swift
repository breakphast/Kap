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
    @Environment(\.dismiss) var dismiss
    @State var parlayMode: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                if viewModel.activeButtons.count > 0 {
                    NavigationLink(destination: SelectedBetsView()) {
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
                        .zIndex(100)
                    }
                }
                
                ScrollView(showsIndicators: false) {
                    GameListingView(parlayMode: $parlayMode, players: players)
                    .navigationBarBackButtonHidden()
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Board")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(parlayMode ? Color.yellow : Color.white)
                                .onTapGesture {
                                    withAnimation {
                                        parlayMode.toggle()
                                    }
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
                    .task {
                        if self.players.isEmpty {
                            self.players = await viewModel.getLeaderboardData()
                        }
                    }
                }
                .padding(.top, 24)

                .fontDesign(.rounded)
                .sheet(isPresented: $parlayMode) {
                    ModalSheet(parlayMode: $parlayMode, players: players)
                }
            }

        }
    }
}

#Preview {
    Board()
}

struct ModalSheet: View {
    @Environment(\.viewModel) private var viewModel
    @Binding var parlayMode: Bool
    var players: [Player]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color("onyx").ignoresSafeArea()  // Set the background color.
            
            VStack(alignment: .leading) {
                Text("Build Parlay")
                    .font(.caption.bold())
                    .padding([.top, .leading], 20)
                
                if viewModel.bets.count > 1 {
                    Button {
                        let parlay = BetService().makeParlay(for: viewModel.bets, player: players[0])
                        viewModel.parlays.append(parlay)
                        parlayMode.toggle()
                        viewModel.activeButtons = [UUID]()
                        viewModel.parlaySelections = []
                    } label: {
                        Text("Place Parlay")
                            .font(.subheadline.bold())
                    }
                    .padding(.leading, 20)
                }
                
                ScrollView {
                    GameListingView(parlayMode: $parlayMode, players: players)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}


struct GameListingView: View {
    @Environment(\.viewModel) private var viewModel
    @Binding var parlayMode: Bool
    var players: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.games, id: \.id) { game in
                GameRow(game: game, parlayMode: $parlayMode, players: players)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal)
    }
}

struct GameRow: View {
    var game: Game
    @Binding var parlayMode: Bool
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
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(options, id: \.id) { betOption in
                    CustomButton(betOption: betOption, buttonText: betOption.betString, parlayMode: $parlayMode) {
                        withAnimation {
                            if parlayMode {
                                let bet = BetService().makeBet(for: game, betOption: betOption, player: players[3])
                                viewModel.bets.append(bet)
//                                print(viewModel.parlaySelections.count)
                            } else {
                                let bet = BetService().makeBet(for: game, betOption: betOption, player: players[3])
                                viewModel.bets.append(bet)
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
