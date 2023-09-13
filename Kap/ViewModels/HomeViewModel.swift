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
    @Published var games: [Game] = []
    @Published var allGames: [Game] = []
    @Published var bets: [Bet] = []
    @Published var generatedBets: [Bet] = []
    @Published var parlays: [Parlay] = []
    @Published var selectedBets: [Bet] = []
    @Published var activeParlays: [Parlay] = []
    @Published var players: [Player] = []
    @Published var leaderboards: [[User]] = [[]]
    
    @Published var activePlayer: Player?
    @Published var activeUserID: String
    @Published var currentWeek = 2
    @Published var activeLeague: League?
    @Published var currentDate: String = ""
    
    @Published var changed: Bool = false
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }()
    
    init(activeUserID: String) {
        self.activeUserID = activeUserID
        
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
    
    func updateGameDayType(game: Game) {
        let db = Firestore.firestore()
        let newGame = db.collection("nflGames").document(game.documentId)
        GameService().updateDayType(for: &games)
        newGame.updateData([
            "dayType": DayType(rawValue: game.dayType ?? "Nope")?.rawValue ?? ""
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            }
        }
    }
    
    func fetchEssentials(updateGames: Bool) async {
        do {
            if updateGames {
                let updatedGames = try await GameService().getGames()
                GameService().addGames(games: updatedGames)
            }
            
            let fetchedUsers = try await UserViewModel().fetchAllUsers()
            let fetchedLeagues = try await LeagueViewModel().fetchAllLeagues()
            let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
            let fetchedGames = try await GameService().fetchGamesFromFirestore().chunked(into: 16)[Int(currentWeek) - 1]
            let fetchedBets = try await BetViewModel().fetchBets(games: fetchedAllGames)
            let fetchedParlays = try await ParlayViewModel().fetchParlays(games: fetchedAllGames)
            
            DispatchQueue.main.async {
                self.users = fetchedUsers
                self.leagues = fetchedLeagues
                self.activeLeague = fetchedLeagues.first
                self.allGames = fetchedAllGames
                self.games = fetchedGames
                self.bets = fetchedBets
                self.parlays = fetchedParlays
                
                GameService().updateDayType(for: &self.games)
                for game in self.games {
                    self.updateGameDayType(game: game)
                }
            }
            
//            GameService().updateDayType(for: &games)
//            for game in games {
//                updateGameDayType(game: game)
//            }
        } catch {
            print("Failed")
        }
    }

    
    func updateAndFetch() async {
        do {
            let alteredGames = games
            for game in alteredGames {
                try await GameService().updateGameScore(game: game)
            }
            
            let newBets = try await BetViewModel().fetchBets(games: allGames)
            let newParlays = try await ParlayViewModel().fetchParlays(games: allGames)

            DispatchQueue.main.async {
                self.games = alteredGames

                for parlay in newParlays {
                    if parlay.result == .pending  {
                        BetViewModel().updateParlay(parlay: parlay)
                    }
                }

                self.parlays = newParlays

                for bet in newBets {
                    let result = bet.game.betResult(for: bet.betOption)
                    if result != .pending {
                        BetViewModel().updateBetResult(bet: bet, result: result)
                    }
                }

                self.bets = newBets
                
                for user in self.users {
                    UserViewModel().updateUserPoints(user: user, bets: self.bets, parlays: self.parlays, week: self.currentWeek, missing: false)
                }
            }
        } catch {
            print("Failed")
        }
    }
}
