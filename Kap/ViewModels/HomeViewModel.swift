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
    @Published var leagueCodes: [String] = ["2222", "5555"]
    @Published var userLeagues: [League] = []
    @Published var leagueType: LeagueType = .weekly
    
    @Published var leagueBets = [BetModel]()
    @Published var userBets = [BetModel]()
    @Published var leagueParlays = [ParlayModel]()
    @Published var userParlays = [ParlayModel]()
    
    @Published var allGameModels: FetchedResults<GameModel>?
    @Published var allBetModels: FetchedResults<BetModel>?
    @Published var allParlayModels: FetchedResults<ParlayModel>?
    @Published var counter: Counter?
        
    let db = Firestore.firestore()
    
    static let keys = [
        "ae61283ad9c8818954d09a7ef48c0887"
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
    
    func checkForUpdatedBets(in context: NSManagedObjectContext, timestamp: Date?, games: [GameModel]) async throws {
        if let timestamp {
            if let activeleagueCode {
                var updatedBets = try await BetViewModel().fetchUpdatedBets(games: games, leagueCode: activeleagueCode)
                
                if let allBets = self.allBetModels {
                    let localBetIDs = Set(allBets).map {$0.id}
                    updatedBets = updatedBets.filter { !localBetIDs.contains($0.id) }
                    let updatedBetsIDs = updatedBets.map { $0.id }
                    let updatedLocalBets = Array(allBets).filter { !updatedBetsIDs.contains($0.id) }

                    if !updatedLocalBets.isEmpty {
                        print("New updated bets detected:", updatedBets.count)
                        try await BetViewModel().updateLocalBetResults(bets: updatedLocalBets, in: context)
                    }
                }
            }
        }
    }
    
    func checkForNewBets(in context: NSManagedObjectContext, timestamp: Date?, games: [GameModel]) async throws {
        if let timestamp {
            if let activeleagueCode {
                var stampedBets = try await BetViewModel().fetchStampedBets(games: games, leagueCode: activeleagueCode, timeStamp: timestamp)
                
                if let allBets = self.allBetModels {
                    let localBetIDs = Set(allBets).map {$0.id}
                    stampedBets = stampedBets.filter { !localBetIDs.contains($0.id) }

                    if !stampedBets.isEmpty {
                        print("New bets detected:", stampedBets.count)
                        convertToBetModels(bets: stampedBets, in: context)
                    }
                }
                
                let deletedStampedBets = try await BetViewModel().fetchDeletedStampedBets(games: self.weekGames, leagueCode: activeleagueCode, deletedTimestamp: timestamp)
                if !deletedStampedBets.isEmpty {
                    for bet in deletedStampedBets {
//                        try await BetViewModel().deleteBet(betID: bet.id)
                        BetViewModel().deleteBetModel(in: context, id: bet.id)
                        if let _ = counter?.timestamp {
                            var timestamp = Date()
                            
                            if let lastTimestamp = leagueBets.last?.timestamp {
                                timestamp = lastTimestamp
                            }
                            if let lastTimestamp = leagueParlays.last?.timestamp {
                                if lastTimestamp > timestamp {
                                    timestamp = lastTimestamp
                                }
                            }
                            counter?.timestamp = timestamp
                            print("New timestamp after removing bet.", timestamp)
                        }
                    }
                }
            }
        }
    }
    
    func updateLocalTimestamp(in context: NSManagedObjectContext, timestamp: Date?) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Counter")
        fetchRequest.predicate = NSPredicate(format: "attributeName == %@", "attributeValue")
        
        let counter = Counter(context: context)
        if let timestamp {
            counter.timestamp = timestamp
            print("Local timestamp:", timestamp)
        } else {
            counter.timestamp = nil
        }
        
        do {
            try context.save()
            self.counter = counter
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    
    func checkForNewParlays(in context: NSManagedObjectContext, timestamp: Date?) async throws {
        if let timestamp {
            if let activeleagueCode {
                var stampedParlays = try await ParlayViewModel().fetchStampedParlays(games: self.weekGames, leagueCode: activeleagueCode, timeStamp: timestamp)
                
                if let allParlays = self.allParlayModels {
                    let localParlayIDs = Set(allParlays).map {$0.id}
                    stampedParlays = stampedParlays.filter { !localParlayIDs.contains($0.id) }

                    if !stampedParlays.isEmpty {
                        print("New parlays detected:", stampedParlays.count)
                        print(stampedParlays.map {$0.betString})
                        convertToParlayModels(parlays: stampedParlays, in: context)
                    }
                }
                
                var deletedStampedParlays = try await ParlayViewModel().fetchDeletedStampedParlays(games: self.weekGames, leagueCode: activeleagueCode, deletedTimeStamp: timestamp)
                if let allParlays = self.allParlayModels {
                    let allParlayModelIDs = allParlays.compactMap { $0.id }
                    let idSet = Set(allParlayModelIDs)
                    deletedStampedParlays = deletedStampedParlays.filter { idSet.contains($0.id) }
                    
                    if !deletedStampedParlays.isEmpty {
                        for parlay in deletedStampedParlays {
                            ParlayViewModel().deleteParlayModel(in: context, id: parlay.id)
                        }
                    }
                }
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
    
    func convertToParlayModels(parlays: [Parlay], in context: NSManagedObjectContext) {
        for parlay in parlays {
            let parlayModel = ParlayModel(context: context)
            
            parlayModel.id = parlay.id
            parlayModel.totalOdds = Int16(parlay.totalOdds)
            parlayModel.result = parlay.result.rawValue
            parlayModel.totalPoints = parlay.totalPoints
            parlayModel.betString = parlay.betString
            parlayModel.playerID = parlay.playerID
            parlayModel.week = Int16(parlay.week)
            parlayModel.leagueCode = parlay.leagueCode
            parlayModel.timestamp = parlay.timestamp
            
            for bet in parlay.bets {
                let betModel = BetModel(context: context)
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
                
                parlayModel.addToBets(betModel)
            }
            
            if parlays.last?.id == parlay.id {
                if let timestamp = parlayModel.timestamp {
                    if let localTimestamp = self.counter?.timestamp {
                        if timestamp > localTimestamp {
                            self.counter?.timestamp = timestamp
                            print("New timestamp from last parlay added: ", parlay.timestamp)
                        }
                    }
                }
            }
        }
        do {
            try context.save()
            print("Saved new parlays locally.")
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func addInitialGames(in context: NSManagedObjectContext) async throws {
        do {
            let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
            await Board().convertToGameModels(games: fetchedAllGames, in: context)
        } catch {
            
        }
    }
    
    func addInitialBets(games: [GameModel], in context: NSManagedObjectContext) async throws {
        do {
            let fetchedBets = try await BetViewModel().fetchBets(games: allGames, leagueCode: activeleagueCode ?? "")
            print(fetchedBets.map({$0.timestamp}))
            if fetchedBets.isEmpty {
                print("No league bets have been placed yet.")
            } else {
                for bet in fetchedBets {
                    BetViewModel().addBetToLocalDatabase(bet: bet, playerID: bet.playerID, in: context)
                }
            }
        } catch {
            
        }
    }
    
    func addInitialParlays(games: [GameModel], in context: NSManagedObjectContext) async throws {
        do {
            let fetchedParlays = try await ParlayViewModel().fetchParlays(games: games, leagueCode: activeleagueCode ?? "")
            if fetchedParlays.isEmpty {
                print("No league parlays have been placed yet.")
            } else {
                for parlay in fetchedParlays {
                    ParlayViewModel().addParlayToLocalDatabase(parlay: parlay, playerID: parlay.playerID, in: context)
                }
            }
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
