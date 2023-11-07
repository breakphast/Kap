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
import CoreData

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
        
        guard scores?.count ?? 0 >= 2 else {
            return datePart
        }

        let safeHomeTeam = homeTeam.replacingOccurrences(of: " ", with: "-")
        let safeAwayTeam = awayTeam.replacingOccurrences(of: " ", with: "-")
        
        return "\(datePart)-\(safeHomeTeam)-vs-\(safeAwayTeam)"
    }
}



class GameService {
    var games: [Game] = []
    private var db = Firestore.firestore()
    let mock = false
    @Environment(\.managedObjectContext) private var viewContext

    func updateCloudGameScores(games: [GameModel]) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let scores = try await mock ? loadnflScoresData() : fetchNFLScoresData()
        do {
            let scoresData = try decoder.decode([ScoreElement].self, from: scores)
            print(scoresData.map {$0.completed})
            for game in games {
                if let scoreElement = scoresData.first(where: { $0.documentId == game.documentID }) {
                    game.homeScore = scoreElement.scores?.first(where: { $0.name == game.homeTeam })?.score
                    game.awayScore = scoreElement.scores?.first(where: { $0.name == game.awayTeam })?.score
                    game.completed = scoreElement.completed
                    
                    let querySnapshot = try await db.collection("nflGames").whereField("id", isEqualTo: game.id ?? "").getDocuments()

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
            "homeSpreadPriceTemp": game.homeSpreadPriceTemp
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
    
    func fetchGamesFromFirestore(week: Int? = nil) async throws -> [Game] {
        let db = Firestore.firestore()
        let querySnapshot: QuerySnapshot?

        if week == nil {
            querySnapshot = try await db.collection("nflGames").getDocuments()
        } else if let weekValue = week {
            querySnapshot = try await db.collection("nflGames").whereField("week", isEqualTo: weekValue).getDocuments()
        } else {
            throw NSError(domain: "InvalidArguments", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Either provide both filter and week or just week"])
        }

        guard let documents = querySnapshot?.documents else {
            return []
        }

        var games = documents.map(parseGameFromDocument)

        games.sort(by: { $0.date < $1.date })
        return games
    }
    
    private func parseGameFromDocument(_ document: QueryDocumentSnapshot) -> Game {
        let data = document.data()

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
        let week = data["week"] as? Int ?? 0

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
        game.week = week

        if let betOptionsDictionaries = data["betOptions"] as? [[String: Any]] {
            game.betOptions = betOptionsDictionaries.compactMap {
                BetOption.fromDictionary($0, game: game)
            }
        }
        return game
    }

    func dateFromISOString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }
    
    func addGames(games: [Game], week: Int) async throws {
        let db = Firestore.firestore()
        let ref = db.collection("nflGames")
        
        let sortedGames = games.sorted { $0.date < $1.date }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for game in sortedGames {
                let gameId = game.documentId
                
                let documentRef = ref.document(gameId)
                
                group.addTask {
                    do {
                        try await BetViewModel().updateDataAsync(document: documentRef, data: game.dictionary)
                    } catch {
                        print("Error adding game: \(error.localizedDescription)")
                    }
                }
            }
            
            for try await _ in group { }
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
    
    func loadnflScoresData() async throws -> Data {
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
        let urlString = "https://api.the-odds-api.com/v4/sports/americanfootball_nfl/odds/?apiKey=\(HomeViewModel.keys.randomElement()!)&regions=us&markets=h2h,spreads,totals&oddsFormat=american&bookmakers=fanduel"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data from server"])
        }
        return data
    }
    
    func fetchNFLScoresData() async throws -> Data {
        let urlString = "https://api.the-odds-api.com/v4/sports/americanfootball_nfl/scores/?daysFrom=3&apiKey=\(HomeViewModel.keys.randomElement()!)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch data from server"])
        }
        return data
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
            "underPriceTemp": underPriceTemp,
            "week": week ?? 0,
        ]
    }
}

let byeGames: [Int: Int] = [
    5: 2,
    6: 1,
    7: 3,
    8: 0,
    9: 2,
    10: 2,
    11: 2,
    12: 0,
    13: 3,
    14: 1,
    15: 0
]

func date(from string: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    return dateFormatter.date(from: string)!
}

let nflSeason2023: [Int: ClosedRange<Date>] = [
    1: date(from: "2023-09-07T00:00:00Z")...date(from: "2023-09-11T23:59:59Z"),
    2: date(from: "2023-09-14T00:00:00Z")...date(from: "2023-09-18T23:59:59Z"),
    3: date(from: "2023-09-21T00:00:00Z")...date(from: "2023-09-25T23:59:59Z"),
    4: date(from: "2023-09-28T00:00:00Z")...date(from: "2023-10-02T23:59:59Z"),
    5: date(from: "2023-10-05T00:00:00Z")...date(from: "2023-10-09T23:59:59Z"),
    6: date(from: "2023-10-12T00:00:00Z")...date(from: "2023-10-16T23:59:59Z"),
    7: date(from: "2023-10-19T00:00:00Z")...date(from: "2023-10-23T23:59:59Z"),
    8: date(from: "2023-10-26T00:00:00Z")...date(from: "2023-10-30T23:59:59Z"),
    9: date(from: "2023-11-02T00:00:00Z")...date(from: "2023-11-06T23:59:59Z"),
    10: date(from: "2023-11-09T00:00:00Z")...date(from: "2023-11-13T23:59:59Z"),
    11: date(from: "2023-11-16T00:00:00Z")...date(from: "2023-11-20T23:59:59Z"),
    12: date(from: "2023-11-23T00:00:00Z")...date(from: "2023-11-27T23:59:59Z"),
    13: date(from: "2023-11-30T00:00:00Z")...date(from: "2023-12-04T23:59:59Z"),
    14: date(from: "2023-12-07T00:00:00Z")...date(from: "2023-12-11T23:59:59Z"),
    15: date(from: "2023-12-14T00:00:00Z")...date(from: "2023-12-18T23:59:59Z"),
    16: date(from: "2023-12-21T00:00:00Z")...date(from: "2023-12-25T23:59:59Z"),
    17: date(from: "2023-12-28T00:00:00Z")...date(from: "2023-12-31T23:59:59Z"),
    18: date(from: "2024-01-06T00:00:00Z")...date(from: "2024-01-07T23:59:59Z")
]
