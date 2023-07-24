//
//  GameService.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//
import Foundation
import SwiftUI
import Firebase

struct ScoreElement: Codable {
    let id: String
    let scores: [Score]
}

class GameService {
    var games: [Game] = []
    
    func getGames() async throws -> [Game] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let odds = try await loadnflData()
        let gamesData = try decoder.decode([GameElement].self, from: odds)
        
        let scores = try await loadnflScoresData()
        let scoresData = try decoder.decode([GameElement].self, from: scores)
        
        games = gamesData.compactMap { Game(gameElement: $0) }
        
        for score in scoresData { 
            if let gameIndex = games.firstIndex(where: { $0.id == score.id }) {
                games[gameIndex].awayScore = score.scores?[0].score
                games[gameIndex].homeScore = score.scores?[1].score
            }
        }
        return games
    }
    
    private func loadnflData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "nflData", withExtension: "json") else {
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
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Game {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "homeTeam": homeTeam,
            "awayTeam": awayTeam,
            "date": Timestamp(date: Date()),
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
