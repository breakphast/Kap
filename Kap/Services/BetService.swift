//
//  BetService.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation
import Observation
import SwiftUI

@Observable class BetService {
    var games: [Game] = []
    var viewModel = AppDataViewModel()

    func fetchGames() async throws {
        do {
            let data = try await loadData(from: "mlbData.json")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let gamesData = try decoder.decode([GameElement].self, from: data)
            games = gamesData.map { Game(gameElement: $0) }
        } catch {
            throw error
        }
    }

    private func loadData(from filename: String) async throws -> Data {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            fatalError("Failed to locate \(filename) in bundle.")
        }

        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            throw error
        }
    }

    func makeBet(for game: Game, betOption: BetOption) -> Bet {
        let allBetResults: [BetResult] = [.win, .loss, .pending]
        let bet = Bet(id: UUID(), betOption: betOption, game: game, type: betOption.betType, result: allBetResults.randomElement(), odds: betOption.odds, selectedTeam: betOption.selectedTeam)
        
        return bet
    }
    
    func makeParlay(for bets: [Bet], player: Player) -> Parlay {
        let parlay = viewModel.createParlayWithinOddsRange(for: player, from: bets)
        return parlay
    }
}
