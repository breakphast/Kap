//
//  GameService.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//
import Foundation

class GameService {
    func getGames() async throws -> [Game] {
        let data = try await loadNflData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let gamesData = try decoder.decode([GameElement].self, from: data)
        return gamesData.compactMap { Game(gameElement: $0) }
    }
    
    private func loadNflData() async throws -> Data {
        guard let url = Bundle.main.url(forResource: "nflData", withExtension: "json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to locate nflData.json"])
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
