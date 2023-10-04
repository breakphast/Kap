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
    @Published var currentWeek = 5
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
    
    static let keys = [
        "4c43e84559d63c5465e9a1d972be7d2d",
        "94d568e36a33661ecd2a6585aed7540a",
        "7015a86284ef3ad5dab00b2bf1f15028",
        "9cde7c14b69228fe849b0343c750622f",
        "e7b29662e60b567df0f26156feb6da67"
    ]
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }()
    
    init() {
        DispatchQueue.main.async {
            Task {
                self.currentWeek = try await self.fetchCurrentWeek() ?? 4
                print("Week: ", self.currentWeek)
                await self.originalFetch(updateScores: false, updateGames: false, updateLeaderboards: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.linear) {
                        self.showingSplashScreen = false
                    }
                }
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
    
    func fetchEssentials(updateGames: Bool, updateScores: Bool) async {
        do {
            var fetchedUsers = try await UserViewModel().fetchAllUsers()
//            for user in fetchedUsers {
//                try await LeagueViewModel().addPlayerToLeague(leagueCode: "nZeeNcgdDZWiya0QFnke", playerId: user.id!)
//            }
            let fetchedLeagues = try await LeagueViewModel().fetchAllLeagues()
            let leaguePlayers = fetchedLeagues.first(where: { $0.code == activeleagueCode })?.players
            if let leaguePlayers = leaguePlayers {
                fetchedUsers = fetchedUsers.filter({ leaguePlayers.contains($0.id!) })
            }
            
            let fetchedAllGames = try await GameService().fetchGamesFromFirestore()
            let fetchedGames = fetchedAllGames.chunked(into: 16)[Int(currentWeek) - 1]
            
            
            if updateGames {
                let updatedGames = try await GameService().getGames()
                let matchingGames = updatedGames.filter { updatedGame in
                    fetchedGames.contains { fetchedGame in
                        return updatedGame.documentId == fetchedGame.documentId
                    }
                }
                GameService().addGames(games: matchingGames)
            }
            
            BetViewModel().fetchBets(games: fetchedAllGames) { bets in
                self.bets = bets
            }
            
            let fetchedParlays = try await ParlayViewModel().fetchParlays(games: fetchedAllGames)
            
            DispatchQueue.main.async { [fetchedUsersCopy = fetchedUsers] in
                self.users = fetchedUsersCopy
                self.leagues = fetchedLeagues
                self.activeLeague = fetchedLeagues.first
                self.allGames = fetchedAllGames
                self.games = fetchedGames.dropLast(byeGames[self.currentWeek] ?? 0)
                self.parlays = fetchedParlays
                self.leagueCodes = self.leagues.map { $0.code }
                
                GameService().updateDayType(for: &self.games)
                for game in self.games {
                    self.updateGameDayType(game: game)
                }
            }
            
            if updateScores {
                await self.updateAndFetch(games: fetchedGames)
            }
        } catch {
            print("Failed with error: \(error.localizedDescription)")
        }
    }

    // updates bets based on new game scores and updates game scores
    func updateAndFetch(games: [Game]) async {
        do {
            let alteredGames = games
            for game in alteredGames {
                try await GameService().updateGameScore(game: game)
            }
            var newBets = [Bet]()
            BetViewModel().fetchBets(games: allGames) { bets in
                newBets = bets
            }
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
                    let result = bet.game.betResult(for: bet)
                    if result != .pending {
                        BetViewModel().updateBetResult(bet: bet, result: result)
                    } else if result == .push {
                        BetViewModel().updateBetResult(bet: bet, result: result)
                    }
                }

                self.bets = newBets
                
                Task {
                    for user in self.users {
                        await UserViewModel().updateUserPoints(user: user, bets: newBets, parlays: self.parlays, week: self.currentWeek, missing: true)
                    }
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
            
            await self.fetchEssentials(updateGames: updateGames, updateScores: updateScores)
        }
    }

}
