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

    func makeBet(for game: Game, betOption: BetOption, player: Player) -> Bet {
        if let betOption = game.betOptions.first(where: { $0.id == betOption.id }) {
            
        }
        let allBetResults: [BetResult] = [.win, .loss, .pending]
        let bet = Bet(id: UUID(), userID: player.user.userID, betOptionID: betOption.id, game: game, type: betOption.betType, result: allBetResults.randomElement(), odds: betOption.odds, selectedTeam: betOption.selectedTeam)
        player.bets[0].append(bet)
        viewModel.bets.append(bet)
        return bet
    }
    
    func makeParlay(for games: [Game], player: Player) {
        let _ = viewModel.createParlayWithinOddsRange(for: player, from: games)
    }
}
