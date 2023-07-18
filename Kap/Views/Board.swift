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
    @State var mainColor: Color = .yellow
    
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
                            .foregroundStyle(mainColor)
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
                                let parlay = BetService().makeParlay(for: viewModel.selectedBets, player: players[0])
                                viewModel.activeParlays.append(parlay)
                                parlayMode.toggle()
                                viewModel.activeButtons = [UUID]()
                            }
                    )
                }
                
                ScrollView(showsIndicators: false) {
                    GameListingView(parlayMode: $parlayMode, mainColor: $mainColor, players: players)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Board")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                            }
                            ToolbarItem(placement: .topBarTrailing) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(parlayMode ? mainColor : Color.white)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            if parlayMode {
                                                viewModel.activeButtons = []
                                            }
                                            parlayMode.toggle()
                                            mainColor =  parlayMode ? Color.redd : .yellow
                                        }
                                    }
                                    .scaleEffect(parlayMode ? 1.2 : 1.0)
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
    @Binding var parlayMode: Bool
    @Binding var mainColor: Color
    var players: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.games, id: \.id) { game in
                GameRow(game: game, parlayMode: $parlayMode, mainColor: $mainColor, players: players)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal)
    }
}

struct GameRow: View {
    var game: Game
    @Binding var parlayMode: Bool
    @Binding var mainColor: Color
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
                    CustomButton(betOption: betOption, buttonText: betOption.betString, parlayMode: $parlayMode, mainColor: $mainColor) {
                        withAnimation {
                            if parlayMode {
                                let bet = BetService().makeBet(for: game, betOption: betOption)
                                viewModel.selectedBets.append(bet)
                                print(viewModel.selectedBets)
                            } else {
                                let bet = BetService().makeBet(for: game, betOption: betOption)
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
