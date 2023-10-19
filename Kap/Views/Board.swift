//
//  Board.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI
import CoreData

struct Board: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
            entity: GameModel.entity(), // Replace 'YourEntity' with your actual entity class
            sortDescriptors: [
                NSSortDescriptor(keyPath: \GameModel.homeTeam, ascending: true) // Assume 'name' is a field of your entity
            ]
        ) var entities: FetchedResults<GameModel>
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GameListingView()
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
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
                            
                            ToolbarItem(placement: .navigationBarTrailing) {
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
//                doThis(games: homeViewModel.weekGames, in: viewContext)
            }
        }
    }
    func deleteAllData(ofEntity entityName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let managedObjectContext = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedObjectContext.execute(batchDeleteRequest)
            try managedObjectContext.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    func doThis(games: [Game], in context: NSManagedObjectContext) {
        for game in games {
            let gameModel = GameModel(context: context) // Now we are using the passed-in context
            
            // Set the attributes on the GameModel from the Game
            gameModel.id = game.id
            gameModel.homeTeam = game.homeTeam
            gameModel.awayTeam = game.awayTeam
            gameModel.date = game.date
            gameModel.homeSpread = game.homeSpread
            gameModel.awaySpread = game.awaySpread
            gameModel.homeMoneyLine = Int16(game.homeMoneyLine)
            gameModel.awayMoneyLine = Int16(game.awayMoneyLine)
            gameModel.over = game.over
            gameModel.under = game.under
            gameModel.completed = game.completed
            gameModel.homeScore = game.homeScore
            gameModel.awayScore = game.awayScore
            gameModel.homeSpreadPriceTemp = game.homeSpreadPriceTemp
            gameModel.awaySpreadPriceTemp = game.awaySpreadPriceTemp
            gameModel.overPriceTemp = game.overPriceTemp
            gameModel.underPriceTemp = game.underPriceTemp
            gameModel.dayType = game.dayType
            gameModel.week = Int16(game.week ?? 0)
            
            
            for betOption in game.betOptions {
                let betOptionModel = BetOptionModel(context: context)
                betOptionModel.id = betOption.id
                betOptionModel.odds = Int16(betOption.odds)
                betOptionModel.spread = betOption.spread ?? 0
                betOptionModel.over = betOption.over
                betOptionModel.under = betOption.under
                betOptionModel.betType = betOption.betType.rawValue
                betOptionModel.selectedTeam = betOption.selectedTeam
                betOptionModel.confirmBet = betOption.confirmBet
                betOptionModel.maxBets = Int16(betOption.maxBets ?? 0)
                betOptionModel.game = gameModel
                
//                let formattedOdds = betOption.odds > 0 ? "+\(betOption.odds)" : "\(betOption.odds)"
//                switch betOption.dayType?.rawValue {
//                case "Spread":
//                    if let spread = betOption.spread {
//                        let formattedSpread = spread > 0 ? "+\(spread)" : "\(spread)"
//                        betOptionModel.betString = "\(formattedSpread)\n\(formattedOdds)"
//                    } else {
//                        betOptionModel.betString = ""
//                    }
//                case "Moneyline":
//                    betOptionModel.betString = formattedOdds
//                case "Over":
//                    betOptionModel.betString = "O \(betOption.over)\n\(formattedOdds)"
//                case "Under":
//                    betOptionModel.betString = "U \(betOption.under)\n\(formattedOdds)"
//                default:
//                    print("Nothing")
//                }
                
                betOptionModel.betString = betOption.betString
                
                gameModel.addToBetOptions(betOptionModel)
                do {
                    try context.save()
                    print("saved", entities.count)
                } catch {
                    // Handle the error appropriately
                    print("Error saving context: \(error)")
                }
                
            }
            print(gameModel)
            
            // Save the context after adding new objects or making changes
            do {
                try context.save()
            } catch {
                // Handle the error appropriately
                print("Error saving context: \(error)")
            }
        }
    }
}

struct GameListingView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    private var thursdayNightGame: [Game] {
        Array(homeViewModel.weekGames.prefix(1))
    }
    
    private var sundayGames: [Game] {
        Array(homeViewModel.weekGames.dropFirst().dropLast(2))
    }
    
    private var sundayNightGame: [Game] {
        Array(homeViewModel.weekGames.suffix(2).prefix(1))
    }
    
    private var mondayNightGame: [Game] {
        Array(homeViewModel.weekGames.suffix(1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionView(title: "Thursday Night Football", games: homeViewModel.weekGames.sorted(by: {$0.date < $1.date}), first: true, dayType: .tnf)
        }
        .padding()
    }
}

struct SectionView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    var title: String
    var games: [Game]
    var first: Bool?
    let dayType: DayType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if first == true {
                    Text("NFL")
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
                if Date() < game.date {
                    GameRow(game: game)
                }
            }
        }
    }
}



struct GameRow: View {
    var game: Game
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @EnvironmentObject var homeViewModel: HomeViewModel
    
    @State private var newGame: GameModel? // Use @State to manage the property
    @Environment(\.managedObjectContext) private var viewContext
    
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
                            .frame(width: 30)
                        Text(nflTeams[game.awayTeam] ?? "")
                    }
                    Text("@")
                    HStack {
                        Image("\(nflLogos[newGame?.homeTeam ?? "lollllll"] ?? "")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                        Text(nflTeams[newGame?.homeTeam ?? "lollllll"] ?? "")
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
        .onAppear {
            // The onAppear is called when the view is about to show, and here you can safely access @Environment properties
            if newGame == nil { // Check to prevent redundant work
                newGame = DataManager(context: viewContext).convertToGameModel(games: [game], in: viewContext).first
            }
        }
        
//        .padding(.bottom, 20)
    }
}

func convertDateToDesiredFormat(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    
    // Convert to Eastern Time
    dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
    dateFormatter.dateFormat = "EEE  h:mma"
    
    let resultStr = dateFormatter.string(from: date).uppercased()
    
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
