//
//  GameService.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//
import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ScoreElement: Codable {
    let id: String
    let sportKey: String
    let sportTitle: String
    let commenceTime: Date
    let completed: Bool
    let homeTeam: String
    let awayTeam: String
    let scores: [Score]?
    let lastUpdate: String?

    enum CodingKeys: String, CodingKey {
        case id, scores, completed, homeTeam = "home_team", awayTeam = "away_team", lastUpdate = "last_update", sportKey = "sport_key", sportTitle = "sport_title", commenceTime = "commence_time"
    }

    var documentId: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: commenceTime)
        
        guard scores?.count ?? 0 >= 2 else { return datePart }  // Safety check, just in case the scores array is too short

        // Converting team names to a URL-safe format
        let safeHomeTeam = scores?[0].name.replacingOccurrences(of: " ", with: "-")
        let safeAwayTeam = scores?[1].name.replacingOccurrences(of: " ", with: "-")
        
        return "\(datePart)-\(safeHomeTeam!)-vs-\(safeAwayTeam!)"
    }
}



class GameService {
    var games: [Game] = []
    private var db = Firestore.firestore()
    let mock = false
    
    func updateGameScore(game: Game) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let scores = try await mock ? loadnflScoresData() : fetchNFLScoresData()
        
        do {
            let scoresData = try decoder.decode([ScoreElement].self, from: scores)
            // Filtering out the exact score data that matches the game id
            if let scoreElement = scoresData.first(where: { $0.documentId == game.documentId }) {
                game.homeScore = scoreElement.scores?.first(where: { $0.name == game.homeTeam })?.score
                game.awayScore = scoreElement.scores?.first(where: { $0.name == game.awayTeam })?.score
                game.completed = scoreElement.completed
                
                let querySnapshot = try await db.collection("nflGames").whereField("id", isEqualTo: game.id).getDocuments()

                if let newGameDocument = querySnapshot.documents.first {
                    try await newGameDocument.reference.updateData([
                        "homeScore": game.homeScore as Any,
                        "awayScore": game.awayScore as Any,
                        "completed": game.completed as Bool
                    ])
                } else {
                    print("No matching game found in Firestore")
                }
            }
        } catch {
            print("Error decoding scores data:", error)
        }
    }
    
    func updateGame(game: Game) {
        let newGame = db.collection("nflGames").document(game.documentId)
        newGame.updateData([
            "awayMoneyline": game.awayMoneyLine,
            "homeMoneyline": game.homeMoneyLine,
            "over": game.over,
            "overPriceTemp": game.overPriceTemp,
            "under": game.under,
            "underPriceTemp": game.underPriceTemp,
            "homeSpread": game.homeSpread,
            "homeSpreadPriceTemp": game.homeSpreadPriceTemp,
            "dayType": game.dayType ?? "Nope"
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func getGames() async throws -> [Game] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let odds = try await mock ? loadnflData() : fetchNFLOddsData()
        let gamesData = try decoder.decode([GameElement].self, from: odds)
        
        games = gamesData.compactMap { Game(gameElement: $0) }
        return games
    }
    
    func convertTimestampToISOString(timestamp: Timestamp) -> String? {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    func fetchGamesFromFirestore() async throws -> [Game] {
        let db = Firestore.firestore()
        let querySnapshot = try await db.collection("nflGames").getDocuments()

        var games = querySnapshot.documents.map { queryDocumentSnapshot -> Game in
            let data = queryDocumentSnapshot.data()
            let id = data["id"] as? String ?? ""
            let homeTeam = data["homeTeam"] as? String ?? ""
            let awayTeam = data["awayTeam"] as? String ?? ""
            let dateString = data["date"] as? Timestamp
            let date2 = convertTimestampToISOString(timestamp: dateString ?? Timestamp(date: Date()))
            let date = dateFromISOString(date2 ?? "")
            let homeSpread = data["homeSpread"] as? Double ?? 0.0
            let awaySpread = data["awaySpread"] as? Double ?? 0.0
            let homeMoneyLine = data["homeMoneyLine"] as? Int ?? 0
            let awayMoneyLine = data["awayMoneyLine"] as? Int ?? 0
            let over = data["over"] as? Double ?? 0.0
            let under = data["under"] as? Double ?? 0.0
            let completed = data["completed"] as? Bool ?? false
            let homeScore = data["homeScore"] as? String
            let awayScore = data["awayScore"] as? String
            let homeSpreadPriceTemp = data["homeSpreadPriceTemp"] as? Double ?? 0.0
            let awaySpreadPriceTemp = data["awaySpreadPriceTemp"] as? Double ?? 0.0
            let overPriceTemp = data["overPriceTemp"] as? Double ?? 0.0
            let underPriceTemp = data["underPriceTemp"] as? Double ?? 0.0
            let dayType = data["dayType"] as? String ?? ""
            
            let gameElement = GameElement(id: id, sportKey: .americanfootball_nfl, sportTitle: .NFL, commenceTime: date ?? Date(), completed: completed, homeTeam: homeTeam, awayTeam: awayTeam, bookmakers: nil, scores: [Score(name: homeTeam, score: homeScore ?? ""), Score(name: awayTeam, score: awayScore ?? "")])
            
            let game = Game(gameElement: gameElement)
            game.homeSpread = homeSpread
            game.awaySpread = awaySpread
            game.homeMoneyLine = homeMoneyLine
            game.awayMoneyLine = awayMoneyLine
            game.over = over
            game.under = under
            game.homeSpreadPriceTemp = homeSpreadPriceTemp
            game.awaySpreadPriceTemp = awaySpreadPriceTemp
            game.overPriceTemp = overPriceTemp
            game.underPriceTemp = underPriceTemp
            game.completed = completed
            game.dayType = dayType

            if let betOptionsDictionaries = data["betOptions"] as? [[String: Any]] {
                game.betOptions = betOptionsDictionaries.compactMap {
                    BetOption.fromDictionary($0, game: game)
                }
            }
            return game
        }
        
        games.sort(by: { $0.date < $1.date })

        return games
    }

    
    func dateFromISOString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }
    
    
    func addGames(games: [Game]) {
        let db = Firestore.firestore()
        let ref = db.collection("nflGames")
        
        let sortedGames = games.sorted { $0.date < $1.date }
        
        for game in sortedGames {
            let gameId = game.documentId
            ref.document(gameId).setData(game.dictionary) { error in
                if let error = error {
                    print("Error adding game: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadnflData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "nflData", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate nflData.json"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func loadmlbData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "mlbData", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate nflData.json"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func loadnflScoresData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "nflScores", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate nflScores.json"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func loadmlbScoresData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "mlbScores", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate nflScores.json"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    func fetchNFLOddsData() async throws -> Data {
        let urlString = "https://api.the-odds-api.com/v4/sports/americanfootball_nfl/odds/?apiKey=e2f24898dae0ba3963da18e6e03456a7&regions=us&markets=h2h,spreads,totals&oddsFormat=american&bookmakers=fanduel"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data from server"])
        }
        return data
    }
    
    private func fetchNFLScoresData() async throws -> Data {
        let urlString = "https://api.the-odds-api.com/v4/sports/americanfootball_nfl/scores/?daysFrom=1&apiKey=e2f24898dae0ba3963da18e6e03456a7"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data from server"])
        }
        return data
    }
    
    func updateDayType(for games: inout [Game]) {
        for game in games.prefix(1) {
            game.betOptions = game.betOptions.map { bet in
                game.dayType = bet.dayType?.rawValue ?? "NAHHH"
                let mutableBet = bet
                mutableBet.dayType = .tnf
                mutableBet.maxBets = 1
                return mutableBet
            }
        }
        
        let sundayAfternoonGamesCount = games.count - 3
        for game in games.dropFirst().prefix(sundayAfternoonGamesCount) {
            game.betOptions = game.betOptions.map { bet in
                game.dayType = bet.dayType?.rawValue ?? "NAHHH"
                let mutableBet = bet
                mutableBet.dayType = .sunday
                mutableBet.maxBets = 7
                return mutableBet
            }
        }
        
        for game in games.dropFirst(sundayAfternoonGamesCount + 1).prefix(1) {
            game.betOptions = game.betOptions.map { bet in
                game.dayType = bet.dayType?.rawValue ?? "NAHHH"
                let mutableBet = bet
                mutableBet.dayType = .snf
                mutableBet.maxBets = 1
                return mutableBet
            }
        }
        
        for game in games.suffix(1) {
            game.betOptions = game.betOptions.map { bet in
                game.dayType = bet.dayType?.rawValue ?? "NAHHH"
                let mutableBet = bet
                mutableBet.dayType = .mnf
                mutableBet.maxBets = 1
                return mutableBet
            }
        }
    }
    
    func deleteCollection(collectionName: String, batchSize: Int = 100, completion: @escaping (Error?) -> Void) {
        // Get a reference to the collection
        let collectionRef = Firestore.firestore().collection(collectionName)
        
        // Create a query against the collection, limited to the first batch
        let query = collectionRef.limit(to: batchSize)
        
        deleteQueryBatch(query: query, batchSize: batchSize, completion: completion)
    }

    private func deleteQueryBatch(query: Query, batchSize: Int, completion: @escaping (Error?) -> Void) {
        query.getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                completion(error)
                return
            }
            
            guard documents.count > 0 else {
                completion(nil)
                return
            }
            
            // Delete documents in a batch
            let batch = query.firestore.batch()
            documents.forEach { batch.deleteDocument($0.reference) }
            
            batch.commit { [self] batchError in
                if let batchError = batchError {
                    completion(batchError)
                } else {
                    // Continue deleting if there are more documents
                    if documents.count == batchSize {
                        self.deleteQueryBatch(query: query, batchSize: batchSize, completion: completion)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Game {
    var documentId: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: date)
        
        // Converting team names to a URL-safe format
        let safeHomeTeam = homeTeam.replacingOccurrences(of: " ", with: "-")
        let safeAwayTeam = awayTeam.replacingOccurrences(of: " ", with: "-")
        
        return "\(datePart)-\(safeHomeTeam)-vs-\(safeAwayTeam)"
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "homeTeam": homeTeam,
            "awayTeam": awayTeam,
            "date": Timestamp(date: date),
            "betOptions": betOptions.map { $0.dictionary },
            "homeSpread": homeSpread,
            "awaySpread": awaySpread,
            "homeMoneyLine": homeMoneyLine,
            "awayMoneyLine": awayMoneyLine,
            "over": over,
            "under": under,
            "completed": completed,
            "homeScore": homeScore ?? NSNull(), // Handle optional values
            "awayScore": awayScore ?? NSNull(),
            "homeSpreadPriceTemp": homeSpreadPriceTemp,
            "awaySpreadPriceTemp": awaySpreadPriceTemp,
            "overPriceTemp": overPriceTemp,
            "underPriceTemp": underPriceTemp
        ]
    }
}

