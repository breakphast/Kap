//
//  swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreData

class HomeViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var leagues: [League] = []
    @Published var weekGames: [GameModel] = []
    @Published var allGames: [GameModel] = []
    @Published var allBets: [BetModel] = []
    @Published var generatedBets: [Bet] = []
    @Published var allParlays: [Parlay] = []
    @Published var selectedBets: [Bet] = []
    @Published var activeParlay: Parlay?
    @Published var players: [Player] = []
    @Published var leaderboards: [[User]] = [[]]
    
    @Published var activePlayer: Player?
    @Published var currentWeek = 7
    @Published var activeLeague: League?
    @Published var currentDate: String = ""
    
    @Published var changed: Bool = false
    @Published var showingSplashScreen = true
    
    @Published var activeleagueCode: String?
    @Published var leagueCodes: [String] = []
    @Published var userLeagues: [League] = []
    @Published var leagueType: LeagueType = .weekly
    
    @Published var leagueBets = [BetModel]()
    @Published var userBets = [BetModel]()
    @Published var leagueParlays = [Parlay]()
    @Published var userParlays = [Parlay]()
    
    @Published var allGameModels: FetchedResults<GameModel>?
    @Published var allBetModels: FetchedResults<BetModel>?
    @Published var counter: Counter?
        
    let db = Firestore.firestore()
    
    static let keys = [
        "31a0c05953fcef15b59b2a998fadafd9"
    ]
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }()
    
    init() {
        DispatchQueue.main.async {
            Task {
                self.currentWeek = try await self.fetchCurrentWeek() ?? 7
                print("Week: ", self.currentWeek)
                try await self.leagues = LeagueViewModel().fetchAllLeagues()
            }
        }
    }
    
    enum FetchError: Error {
        case noDocumentsFound
    }
    
    enum Week: Int {
        case week1 = 1
        case week2
        case week3
        case week4
        case week5
        case week6
        
        static func from(dayDifference: Int) -> Week {
            let currentWeekNumber = (dayDifference / 7) + 1
            return Week(rawValue: currentWeekNumber) ?? .week1
        }
    }
    
    func updateLocalTimestamp(in context: NSManagedObjectContext, date: Date) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Counter")
        fetchRequest.predicate = NSPredicate(format: "attributeName == %@", "attributeValue")
        
        let counter = Counter(context: context)
        counter.timestamp = Date()
        print("New timestamp:", counter.timestamp)
        
        do {
            try context.save()
            self.counter = counter
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func checkForNewBets(in context: NSManagedObjectContext, timestamp: Date?) async throws {
        var stampedBets = try await BetViewModel().fetchStampedBets(games: self.weekGames, leagueCode: "2222", timeStamp: timestamp == nil ? nil : timestamp)
        
        if let allBets = self.allBetModels {
            let localBetIDs = Set(allBets).map {$0.id}
            stampedBets = stampedBets.filter { !localBetIDs.contains($0.id) }

            if !stampedBets.isEmpty {
                print("New bets detected:", stampedBets.count)
                print(stampedBets.map {$0.betString})
                convertToBetModels(bets: stampedBets, in: context)
            }
        }
    }
    
    func convertToBetModels(bets: [Bet], in context: NSManagedObjectContext) {
        for bet in bets.sorted(by: {$0.game.date ?? Date() < $1.game.date ?? Date()}) {
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
            
            if bets.last?.id == bet.id {
                if let timestamp = betModel.timestamp {
                    self.counter?.timestamp = timestamp
                    print("New timestamp from last bet added: ", bet.timestamp ?? "")
                }
            }
        }
        do {
            try context.save()
            print("Saved new bets locally.")
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func fetchEssentials(updateGames: Bool, updateScores: Bool, league: League, in context: NSManagedObjectContext) async {
        do {
            guard let leaguePlayers = league.players else {
                print("Error: league players are nil.")
                return
            }

            let fetchedUsers = try await UserViewModel().fetchAllUsers(leagueUsers: leaguePlayers)
            let relevantUsers = fetchedUsers.filter { leaguePlayers.contains($0.id ?? "") }

            DispatchQueue.main.async {
                Task {
                    do {
                        if let allGameModels = self.allGameModels {
                            self.allGames = Array(allGameModels)
                            self.weekGames = Array(allGameModels).filter { $0.week == self.currentWeek }
                        }
                    }
                }
            }
            
            if let allGameModels = allGameModels {
//                let leagueBetsResult = try await BetViewModel().fetchBets(games: Array(allGameModels), leagueCode: league.code)
                let leagueParlaysResult = try await ParlayViewModel().fetchParlays(games: Array(allGameModels)).filter({ $0.leagueCode == league.code })
                DispatchQueue.main.async {
//                    self.leagueBets = leagueBetsResult
                    self.leagueParlays = leagueParlaysResult
                }
            }

//            if updateScores {
//                await self.updateAndFetch(games: self.weekGames, league: league)
//            }
//
//            if updateGames {
//                let updatedGames = try await GameService().getGames()
//                let matchingGames = updatedGames.filter { updatedGame in
//                    self.weekGames.contains { fetchedGame in
//                        return updatedGame.documentId == fetchedGame.documentId
//                    }
//                }
//                
//                GameService().addGames(games: matchingGames, week: currentWeek)
//            }

            DispatchQueue.main.async {
                self.users = relevantUsers
                self.leagueCodes = self.leagues.map { $0.code }
            }
        } catch {
            print("Failed with error: \(error.localizedDescription)")
        }
    }

    // updates bets based on new game scores and updates game scores
    func updateAndFetch(games: [Game], league: League) async {
        do {
            let alteredGames = games
            for game in alteredGames {
                try await GameService().updateGameScore(game: game)
            }
            if let allGameModels = allGameModels {
                let newBets = try await BetViewModel().fetchBets(games: Array(allGameModels), leagueCode: league.code)
                let newParlays = try await ParlayViewModel().fetchParlays(games: Array(allGameModels))
                DispatchQueue.main.async {
//                    self.weekGames = alteredGames
                    for parlay in newParlays {
                        if parlay.result == .pending  {
                            BetViewModel().updateParlay(parlay: parlay)
                        }
                    }

                    self.allParlays = newParlays

                    for bet in newBets {
                        let result = bet.game.betResult(for: bet)
                        if result != .pending {
                            BetViewModel().updateBetResult(bet: bet, result: result)
                        } else if result == .push {
                            BetViewModel().updateBetResult(bet: bet, result: result)
                        }
                    }

//                    self.allBets = newBets
                }
            }

        } catch {
            print("Failed update and fetch", error.localizedDescription)
        }
    }
    
    func addInitialGames(in context: NSManagedObjectContext) async throws {
        do {
            let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
            await Board().doThis(games: fetchedAllGames, in: context)
        } catch {
            
        }
    }
    
    func originalFetch(updateScores: Bool, updateGames: Bool, updateLeaderboards: Bool) async {
        do {
            let activeDate = self.formatter.string(from: Date())
            
            DispatchQueue.main.async {
                self.currentDate = activeDate
            }
        }
    }
    
    func setCurrentWeek() {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
        let daysSinceSunday = (components.weekday! - calendar.firstWeekday + 7) % 7
        guard let lastSunday = calendar.date(byAdding: .day, value: -daysSinceSunday, to: Date()) else {
            return
        }
        
        guard let diffDays = calendar.dateComponents([.day], from: lastSunday, to: Date()).day else {
            return
        }
        
        currentWeek = Week.from(dayDifference: diffDays).rawValue
    }
    
    func fetchDate() async throws -> String? {
        let db = Firestore.firestore()
        let docRef = db.collection("activeDate").document("NBpRBsY6JHSQj87MdTd5")
        
        let document = try await docRef.getDocument()
        if document.exists {
            return document.data()?["currentDate"] as? String
        }
        return nil
    }
    
    func fetchCurrentWeek() async throws -> Int? {
        let db = Firestore.firestore()
        let docRef = db.collection("currentWeek").document("currentWeek")
        
        let document = try await docRef.getDocument()
        if document.exists {
            return document.data()?["week"] as? Int
        }
        return nil
    }
    
    func deleteGame(game: Game) async throws {
        let db = Firestore.firestore()
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("mlbGames").document(game.documentId).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                    print("Deleted bet \(game.documentId)")
                }
            }
        }
    }
    
    func updateDate(date: String) {
        let db = Firestore.firestore()
        let newbet = db.collection("activeDate").document("NBpRBsY6JHSQj87MdTd5")
        newbet.updateData([
            "currentDate": date
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateGameWeek(game: Game, week: Int) {
        let db = Firestore.firestore()
        let newGame = db.collection("nflGames").document(game.documentId)
        newGame.updateData([
            "week": week
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            }
        }
    }

}
