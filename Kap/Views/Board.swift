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
                    GameListingView()
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Text("Loch Sports")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
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
                        .clipShape(TopRoundedRectangle(radius: 12))
                        .shadow(radius: 10)
                    }
                    .zIndex(100)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if viewModel.selectedBets.count > 1 {
                                    viewModel.activeParlays = []
                                    let parlay = ParlayViewModel().makeParlay(for: viewModel.selectedBets, playerID: viewModel.activeUserID, week: viewModel.currentWeek)
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
            SectionView(title: "Thursday Night Football", games: thursdayNightGame, first: true, dayType: .tnf)
            SectionView(title: "Sunday Afternoon", games: sundayGames, dayType: .sunday)
            SectionView(title: "Sunday Night Football", games: sundayNightGame, dayType: .snf)
            SectionView(title: "Monday Night Football", games: mondayNightGame, dayType: .mnf)
        }
        .padding()
    }
}

struct SectionView: View {
    @Environment(\.viewModel) private var viewModel
    var title: String
    var games: [Game]
    var first: Bool?
    let dayType: DayType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(dayType.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.oW)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.lion)
                    .cornerRadius(4)
                    .padding(.bottom)
                
                Spacer()

                if first != nil {
                    HStack(spacing: 10) {
                        Text("Spread")
                            .frame(maxWidth: UIScreen.main.bounds.width / (1.75 * 3), alignment: .center) // Adjust width according to each placeholder.
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
        VStack(alignment: .leading, spacing: 16) {
            Text(convertDateToDesiredFormat(game.date))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image("\(nflLogos[game.awayTeam] ?? "")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40)
                        Text(nflTeams[game.awayTeam] ?? "")
                    }
                    Text("@")
                    HStack {
                        Image("\(nflLogos[game.homeTeam] ?? "")")
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
        }
        .padding(.bottom, 20)
    }
}

func convertDateToDesiredFormat(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    
    // Convert to Eastern Time
    dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
    dateFormatter.dateFormat = "EEE  h:mma"
    
    var resultStr = dateFormatter.string(from: date).uppercased()
    
//        // Append 'ET' to the end
//        resultStr += "  ET"
    
    return resultStr
}

func convertDateForBetCard(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    
    // Convert to Eastern Time
    dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
    
    // Setting the desired format
    dateFormatter.dateFormat = "MMM d, h:mma"
    
    var resultStr = dateFormatter.string(from: date).uppercased()
    
    // Append 'ET' to the end
    resultStr += " ET"
    
    return resultStr
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
