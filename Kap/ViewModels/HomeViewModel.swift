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
    @Published var betCount = 0
    @Published var counter: Counter?
    
    let db = Firestore.firestore()
    
    static let keys = [
        "ab5225bbaeaf25a64a6bba6340bdf2e2"
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
    
    func fetchCounter() async throws -> Int {
        let docRef = db.collection("helpers").document("betCount")
        do {
            let document = try await docRef.getDocument()
            if let fieldValue = document.get("totalBets") as? Int {
                return fieldValue
            } else {
                throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Field not found or not an integer"])
            }
        } catch {
            throw error
        }
    }
    
    func updateLocalTimestamp(in context: NSManagedObjectContext) {
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
    
    func fetchEssentials(updateGames: Bool, updateScores: Bool, league: League) async {
        do {
            guard let leaguePlayers = league.players else {
                print("Error: league players are nil.")
                return
            }

            let fetchedUsers = try await UserViewModel().fetchAllUsers(leagueUsers: leaguePlayers)
            let relevantUsers = fetchedUsers.filter { leaguePlayers.contains($0.id ?? "") }

//            let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
            
            DispatchQueue.main.async {
                Task {
                    do {
                        self.betCount = try await self.fetchCounter()
                        if let allGameModels = self.allGameModels {
                            self.allGames = Array(allGameModels)
                            self.weekGames = Array(allGameModels).filter { $0.week == self.currentWeek }
                        }
                        if let allBetModels = self.allBetModels {
                            self.leagueBets = Array(allBetModels).filter({$0.leagueCode == league.code})
                        }
                    } catch {
                        
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
