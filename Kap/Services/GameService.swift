//
//  GameService.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//
import Foundation

struct ScoreElement: Codable {
    let id: String
    let scores: [Score]
}

class GameService {
    var games: [Game] = []
    
    func getGames() async throws -> [Game] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let odds = try await loadMlbData()
        let gamesData = try decoder.decode([GameElement].self, from: odds)
        
        let scores = try await loadMlbScoresData()
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
    
    private func loadMlbData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "mlbData", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate mlbData.json"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func loadMlbScoresData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "mlbScores", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate mlbScores.json"])
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
