//
//  Board.swift
//  Kap
//
//  Created by Desmond Fitch on 7/15/23.
//

import SwiftUI
import CoreData
import FirebaseFirestore
import Firebase
import FirebaseFirestoreSwift

struct Board: View {
    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    @EnvironmentObject var homeViewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var leagueViewModel: LeagueViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let db = Firestore.firestore()
    
    @FetchRequest(
        entity: GameModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \GameModel.date, ascending: true)
        ]
    ) var allGameModels: FetchedResults<GameModel>
    
    @FetchRequest(
        entity: BetModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \BetModel.timestamp, ascending: true)
        ]
    ) var allBetModels: FetchedResults<BetModel>
    
    @FetchRequest(
        entity: ParlayModel.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \ParlayModel.timestamp, ascending: true)
        ]
    ) var allParlayModels: FetchedResults<ParlayModel>
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color("onyx").ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    GameListingView(allGameModels: homeViewModel.weekGames)
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
                .refreshable {
                    Task {
                        do {
                            try await pedestrianRefresh()
//                            try await personalRefresh()
                        } catch {
                            
                        }
                    }
                }
                
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
//                deleteAllData(ofEntity: "GameModel") { result in }
//                deleteAllData(ofEntity: "BetOptionModel") { result in }
//                deleteAllData(ofEntity: "Counter") { result in }
//                deleteAllData(ofEntity: "BetModel") { result in }
//                deleteAllData(ofEntity: "ParlayModel") { result in }
            }
        }
    }
    
    func pedestrianRefresh() async throws {
        if let allGameModels = homeViewModel.allGameModels {
            if let newWeek = try await homeViewModel.fetchCurrentWeek(), newWeek > homeViewModel.currentWeek {
                homeViewModel.currentWeek = newWeek
            }
            try await updateLocalGameOdds(games: Array(allGameModels).filter({$0.week == homeViewModel.currentWeek}), week: homeViewModel.currentWeek, in: viewContext)
            homeViewModel.allGameModels = allGameModels
            
            try await BetViewModel().updateLocalBetResults(games: Array(allGameModels), week: homeViewModel.currentWeek, bets: Array(allBetModels), leagueCode: homeViewModel.activeleagueCode ?? "", in: viewContext)
            homeViewModel.allBetModels = allBetModels
        }
    }
    
    func personalRefresh() async throws {
        try await updateCloudGameOdds()
        try await updateLocalGameOdds(games: homeViewModel.weekGames, week: homeViewModel.currentWeek, in: viewContext)
        homeViewModel.allGameModels = allGameModels
        // cloud scores
        try await GameService().updateCloudGameScores(games: homeViewModel.weekGames)
        homeViewModel.allGameModels = allGameModels
        try await updateLocalGameScores(in: viewContext)
        homeViewModel.allGameModels = allGameModels
        // cloud bets and parlays results
        try await BetViewModel().updateCloudBetResults(bets: homeViewModel.leagueBets)
        homeViewModel.allBetModels = allBetModels
        try await BetViewModel().updateLocalBetResults(games: Array(allGameModels), week: homeViewModel.currentWeek, bets: Array(allBetModels), leagueCode: homeViewModel.activeleagueCode ?? "", in: viewContext)
        homeViewModel.allBetModels = allBetModels
//        try await ParlayViewModel().updateCloudParlayResults(parlays: homeViewModel.leagueParlays)
//        homeViewModel.allParlayModels = allParlayModels
        
        
    }
    
    func updateLocalGameOdds(games: [GameModel], week: Int, in context: NSManagedObjectContext) async throws {
        // this is locally updating odds to core data
        let updatedGames = try await GameService().fetchGamesFromFirestore(week: week)
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
                game.betOptions = []
                game.homeScore = newGame.homeScore
                game.awayScore = newGame.awayScore
                game.completed = newGame.completed

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
                }
            }
        }
        do {
            try context.save()
            print("Updated \(games.count) game odds locally..")
        } catch {
            print("Error saving context: \(error)")
        }
    }

    func updateCloudGameOdds() async throws {
        let updatedGames = try await GameService().getGames()
        try await GameService().addGames(games: updatedGames, week: homeViewModel.currentWeek)
    }
    
    func updateLocalGameScores(in context: NSManagedObjectContext) async throws {
        let updatedGames = try await GameService().fetchGamesFromFirestore(week: homeViewModel.currentWeek)
        for game in updatedGames {
            if let newGame = updatedGames.first(where: {$0.documentId == game.documentId}) {
                game.completed = newGame.completed
                game.homeScore = newGame.homeScore
                game.awayScore = newGame.awayScore
            }
        }
        try context.save()
    }
    
    func updateGameAttribute(game: GameModel, in context: NSManagedObjectContext) {
        
    }
    
    func convertToGameModels(games: [Game], in context: NSManagedObjectContext) async -> [GameModel] {
        var gameModels = [GameModel]()
        
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
            }
            gameModels.append(gameModel)
        }
        return gameModels
    }

    func deleteAllData(ofEntity entityName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try viewContext.execute(batchDeleteRequest)
            try viewContext.save()
            print("Deleted all \(entityName) data.")
            completion(.success(()))
        } catch {
            print("Failed to delete all \(entityName) data.")
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
            SectionView(title: "NFL", games: allGameModels.sorted(by: {$0.date ?? Date() < $1.date ?? Date()}), first: true)
        }
        .padding()
    }
}

struct SectionView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    var title: String
    var games: [GameModel]
    var first: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if first == true {
                    Text(title)
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
                            .frame(maxWidth: UIScreen.main.bounds.width / (1.75 * 3), alignment: .center)
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
