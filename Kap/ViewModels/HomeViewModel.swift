//
//  swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var leagues: [League] = []
    @Published var weekGames: [Game] = []
    @Published var allGames: [Game] = []
    @Published var allBets: [Bet] = []
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
    
    @Published var leagueBets = [Bet]()
    @Published var userBets = [Bet]()
    @Published var leagueParlays = [Parlay]()
    @Published var userParlays = [Parlay]()
    
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
    
    func fetchEssentials(updateGames: Bool, updateScores: Bool, league: League) async {
        do {
            // Safely unwrap league players
            guard let leaguePlayers = league.players else {
                print("Error: league players are nil.")
                return
            }

            let fetchedUsers = try await UserViewModel().fetchAllUsers(leagueUsers: leaguePlayers)
            let relevantUsers = fetchedUsers.filter { leaguePlayers.contains($0.id ?? "") }

            let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
            
            DispatchQueue.main.async {
                self.allGames = fetchedAllGames
                self.weekGames = fetchedAllGames.filter { $0.week == self.currentWeek }
//                
//                for i in 7...16 {
//                    print("Starting...")
//                    var weekGamess = fetchedAllGames.filter { $0.week == i }.sorted(by: {$0.date < $1.date})
//                    GameService().updateDayType(for: &weekGamess)
//                    for game in weekGamess {
//                        if let dayType = game.dayType {
//                            self.updateGameDayType(game: game)
//                            print(game.documentId, "should have updated")
//                        }
//                    }
//                }
            }

            let leagueBetsResult = try await BetViewModel().fetchBets(games: fetchedAllGames, leagueCode: league.code)
            let leagueParlaysResult = try await ParlayViewModel().fetchParlays(games: fetchedAllGames).filter({ $0.leagueCode == league.code })
            DispatchQueue.main.async {
                self.leagueBets = leagueBetsResult
                self.leagueParlays = leagueParlaysResult
            }

            if updateScores {
                await self.updateAndFetch(games: self.weekGames, league: league)
            }

            if updateGames {
                let updatedGames = try await GameService().getGames()
                let matchingGames = updatedGames.filter { updatedGame in
                    self.weekGames.contains { fetchedGame in
                        return updatedGame.documentId == fetchedGame.documentId
                    }
                }
                
                GameService().addGames(games: matchingGames, week: currentWeek)
                
//                for game in self.weekGames {
//                    updateGameDayType(game: game)
//                }
            }

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
            let newBets = try await BetViewModel().fetchBets(games: allGames, leagueCode: league.code)
            let newParlays = try await ParlayViewModel().fetchParlays(games: allGames)

            DispatchQueue.main.async {
                self.weekGames = alteredGames
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
                    }
                }

                self.allBets = newBets
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
            
//            await self.fetchEssentials(updateGames: updateGames, updateScores: updateScores, league: )
        }
    }
    
    func setCurrentWeek() {
        let calendar = Calendar.current
        
        // Finding the most recent Sunday
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
    
    // Converting fetchDate to use async/await
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
    
//    func updateGameDayType(game: Game) {
//        let db = Firestore.firestore()
//        let gameDocument = db.collection("nflGames").document(game.documentId)
//
//        if let gameDayType = game.dayType {
//            gameDocument.updateData([
//                "dayType": gameDayType
//            ]) { err in
//                if let err = err {
//                    print("Error updating document: \(err)")
//                }
//            }
//        }
//    }
    
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
