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
        entity: GameModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GameModel.homeTeam, ascending: true)
        ]
    ) var allGameModels: FetchedResults<GameModel>
    
    @FetchRequest(
        entity: BetModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BetModel.id, ascending: true)
        ]
    ) var allBetModels: FetchedResults<BetModel>
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GameListingView(allGameModels: Array(allGameModels).filter({$0.week == homeViewModel.currentWeek}))
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
                do {
                    try await fetchCloudTimestamp()
                    
                    if let timestamp = homeViewModel.counter?.timestamp {
                        var stampedBets = try await BetViewModel().fetchStampedBets(games: homeViewModel.weekGames, leagueCode: "2222", timeStamp: timestamp)
                        if !stampedBets.isEmpty {
                            let localBetIDs = Set(allBetModels.map {$0.id})
                            stampedBets = stampedBets.filter { !localBetIDs.contains($0.id) }
                            print("New bets detected:", stampedBets.count)
                            print(stampedBets.map {$0.betString})
                            convertToBetModels(bets: stampedBets, in: viewContext)
                        }
                    }
                } catch {
                    
                }
//                updateEntity(in: viewContext)
//                do {
//                    try await BetViewModel().updateEntity()
//                } catch {
//                    
//                }
//                updateGameAttribute(games: homeViewModel.allGames, in: viewContext)
                
//                updateGameOdds(games: homeViewModel.weekGames, in: viewContext)
//                deleteAllData(ofEntity: "BetModel") { result in
//                    switch result {
//                    case .success(_):
//                        print("YAY")
//                    case .failure(_):
//                        print("NAY")
//                    }
//                }
//                deleteAllData(ofEntity: "BetOptionModel") { result in
//                    
//                }
                
//                doThisForBets(bets: homeViewModel.leagueBets, in: viewContext)
                
//                do {
//                    let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
//                    doThis(games: fetchedAllGames, in: viewContext)
//                    
//                } catch {
//                    
//                }
            }
        }
    }
    
    private func fetchCloudTimestamp() async throws {
        let request: NSFetchRequest<Counter> = Counter.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let result = try viewContext.fetch(request)
            
            homeViewModel.counter = result.first
            if let counter = homeViewModel.counter {
                print("Current timestamp: ", counter.timestamp)
            }
            
        } catch {
            print("Failed to fetch BetModel: \(error.localizedDescription)")
        }
    }
    
    private func updateEntity(in context: NSManagedObjectContext) {
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Counter")
        fetchRequest.predicate = NSPredicate(format: "attributeName == %@", "attributeValue")
        
        let counter = Counter(context: context)
        counter.betCount = 0
        counter.timestamp = Date()
        
        do {
            try context.save()
            print(counter)
            
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func convertToBetModels(bets: [Bet], in context: NSManagedObjectContext) {
        for bet in bets {
            let betModel = BetModel(context: context)
            
            // Set the attributes on the GameModel from the Game
            betModel.id = bet.id
            betModel.betOption = bet.betOption
            betModel.game = bet.game
            betModel.type = bet.type.rawValue
            betModel.result = bet.result?.rawValue ?? "Pending"
            betModel.odds = Int16(bet.odds)
            betModel.selectedTeam = bet.selectedTeam
            betModel.playerID = bet.playerID
            betModel.week = Int16(bet.week)
            betModel.leagueCode = bet.leagueCode
            betModel.stake = 100.0
            betModel.betString = bet.betString
            betModel.points = bet.points ?? 0
            betModel.betOptionString = bet.betOptionString
            betModel.timestamp = bet.timestamp

            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    func updateGameOdds(games: [GameModel], in context: NSManagedObjectContext) async throws {
        let updatedGames = try await GameService().getGames()
        for game in games {
            if let newGame = updatedGames.first(where: {$0.documentId == game.documentID}) {
                
                game.homeSpread = newGame.homeSpread
                game.awaySpread = newGame.awaySpread
                game.homeMoneyLine = Int16(newGame.homeMoneyLine)
                game.awayMoneyLine = Int16(newGame.awayMoneyLine)
                game.over = newGame.over
                game.under = newGame.under
                game.homeSpreadPriceTemp = newGame.homeSpreadPriceTemp
                game.awaySpreadPriceTemp = newGame.awaySpreadPriceTemp
                game.overPriceTemp = newGame.overPriceTemp
                game.underPriceTemp = newGame.underPriceTemp
                
                for betOption in newGame.betOptions {
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
                    betOptionModel.game = game
                    betOptionModel.betString = betOption.betString
                    
                    game.addToBetOptions(betOptionModel)
                    do {
                        try context.save()
                    } catch {
                        print("Error saving context: \(error)")
                    }
                }
            }
        }
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func updateGameAttribute(games: [GameModel], in context: NSManagedObjectContext) {
        if let game = games.first(where: {$0.documentID == "2023-10-30-Detroit-Lions-vs-Las-Vegas-Raiders"}) {
            game.dayType = "MNF"
            game.week = 8
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }

    static func doThis(games: [Game], in context: NSManagedObjectContext) {
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
            
            var documentId: String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let datePart = formatter.string(from: gameModel.date ?? Date())
                
                // Converting team names to a URL-safe format
                let safeHomeTeam = (gameModel.homeTeam ?? "").replacingOccurrences(of: " ", with: "-")
                let safeAwayTeam = (gameModel.awayTeam ?? "").replacingOccurrences(of: " ", with: "-")
                
                return "\(datePart)-\(safeHomeTeam)-vs-\(safeAwayTeam)"
            }
            gameModel.documentID = documentId
            
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
                betOptionModel.betString = betOption.betString
                
                gameModel.addToBetOptions(betOptionModel)
                do {
                    try context.save()
                } catch {
                    print("Error saving context: \(error)")
                }
                
            }
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
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
    func deleteFirstOption() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "BetModel")
        fetchRequest.fetchLimit = 1
        
        do {
            let fetchedResults = try viewContext.fetch(fetchRequest) as? [NSManagedObject]
            if let objectToDelete = fetchedResults?.first {
                viewContext.delete(objectToDelete)
                
                do {
                    try viewContext.save()
                } catch {
                    print("Error saving context after deletion: \(error)")
                }
            } else {
                print("No object to delete")
            }
        } catch {
            print("Error fetching objects: \(error)")
        }
    }
}

struct GameListingView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    let allGameModels: [GameModel]
    
    private var thursdayNightGame: [GameModel] {
        Array(homeViewModel.weekGames.prefix(1))
    }
    
    private var sundayGames: [GameModel] {
        Array(homeViewModel.weekGames.dropFirst().dropLast(2))
    }
    
    private var sundayNightGame: [GameModel] {
        Array(homeViewModel.weekGames.suffix(2).prefix(1))
    }
    
    private var mondayNightGame: [GameModel] {
        Array(homeViewModel.weekGames.suffix(1))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionView(title: "Thursday Night Football", games: allGameModels.sorted(by: {$0.date ?? Date() < $1.date ?? Date()}), first: true, dayType: .tnf)
        }
        .padding()
    }
}

struct SectionView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    var title: String
    var games: [GameModel]
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
                if Date() < game.date ?? Date() {
                    GameRow(game: game)
                }
            }
        }
    }
}



struct GameRow: View {
    var game: GameModel
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var newGame: GameModel? // Use @State to manage the property
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
            entity: GameModel.entity(), // Replace 'YourEntity' with your actual entity class
            sortDescriptors: [
                NSSortDescriptor(keyPath: \GameModel.date, ascending: true) // Assume 'name' is a field of your entity
            ]
        ) var allGameModels: FetchedResults<GameModel>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(convertDateToDesiredFormat(game.date ?? Date()))
                .font(.system(.caption2, design: .rounded, weight: .semibold))
            
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image("\(nflLogos[game.awayTeam ?? ""] ?? "")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                        Text(nflTeams[game.awayTeam ?? ""] ?? "")
                    }
                    Text("@")
                    HStack {
                        Image("\(nflLogos[game.homeTeam ?? "lollllll"] ?? "")")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                        Text(nflTeams[game.homeTeam ?? "lollllll"] ?? "")
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
