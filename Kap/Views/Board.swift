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
    @State var selectedOption = "DowgHouse"
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GameListingView()
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Text(viewModel.activeUser?.name ?? "")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .onTapGesture {
                                        viewModel.activeUser = viewModel.users.randomElement()
                                    }
                            }
                            
                            ToolbarItem(placement: .principal) {
                                Menu {
                                    Button("DowgHouse", action: {
                                        selectedOption = "DowgHouse"
                                    })
                                    Button("Studwell ggs", action: {
                                        selectedOption = "Studwell ggs"
                                    })
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(selectedOption.isEmpty ? (viewModel.activeLeague?.name ?? "") : selectedOption)
                                        Image(systemName: "chevron.down")
                                            .font(.caption2.bold())
                                    }
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)// Adjust padding as needed
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
                                }
                            }
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
                                if viewModel.selectedBets.count > 1 && calculateParlayOdds(bets: viewModel.selectedBets) >= 400 {
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
                        }
                    Rectangle()
                        .frame(height: 20)
                        .foregroundStyle(.clear)
                }
                .fontDesign(.rounded)
                
                if viewModel.selectedBets.count > 0 {
                    Spacer()
                    NavigationLink(destination: Betslip()) {
                        ZStack {
                            Color.lion
                            
                            Text("Betslip")
                            .font(.title.bold())
                            .fontDesign(.rounded)
                            .foregroundStyle(.oW)
                        }
                        .frame(height: 60)
                        .clipShape(TopRoundedRectangle(radius: 20))
                        .shadow(radius: 10)
                    }
                    .zIndex(100)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if viewModel.selectedBets.count > 1 {
                                    viewModel.activeParlays = []
                                    let parlay = ParlayViewModel().makeParlay(for: viewModel.selectedBets, playerID: viewModel.activeUser?.id ?? "", week: viewModel.currentWeek)
                                    if parlay.totalOdds >= 400 {
                                        viewModel.activeParlays.append(parlay)
                                    }
                                } else {
                                    viewModel.activeParlays = []
                                }
                            }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)

        }
    }
}

#Preview {
    Board()
}

struct GameListingView: View {
    @Environment(\.viewModel) private var viewModel
    
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
        .padding()
    }
}

struct SectionView: View {
    @Environment(\.viewModel) private var viewModel
    var title: String
    var games: [Game]
    
    @State private var dayType: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.lion)
                    .padding(.bottom)
            }
            
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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image("\(nflLogos[game.awayTeam]!)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                    Text(nflTeams[game.awayTeam] ?? "")
                }
                Text("@")
                HStack {
                    Image("\(nflLogos[game.homeTeam]!)")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                    Text(nflTeams[game.homeTeam] ?? "")
                }
            }
            .font(.subheadline.bold())
            .frame(maxWidth: UIScreen.main.bounds.width / 3, alignment: .leading)
            .lineLimit(2)
            
            Spacer()
            
            let bets = BetViewModel().generateBetsForGame(game)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(bets, id: \.id) { bet in
                    CustomButton(bet: bet, buttonText: bet.betOption.betString) {
                        withAnimation {
                            bet.week = viewModel.currentWeek
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

struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.maxY)) // bottom left
        path.addLine(to: CGPoint(x: 0, y: radius)) // top left
        path.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0)) // before top right corner
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: radius), radius: radius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // bottom right

        return path
    }
}
