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
            let data = try await loadData(from: "nflData.json")
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
        let bet = Bet(id: UUID(), betOption: betOption, game: game, type: betOption.betType, result: .pending, odds: betOption.odds, selectedTeam: betOption.selectedTeam)
        
        return bet
    }
    
    func placeBet(bet: Bet, player: Player) {
        let placedBet = makeBet(for: bet.game, betOption: bet.betOption)
        
        if !player.bets[0].contains(where: { $0.game.id == placedBet.game.id }) {
            player.bets[0].append(placedBet)
        }
    }
    
    func makeParlay(for bets: [Bet]) -> Parlay {
        let parlay = Parlay(id: UUID(), bets: bets, result: .pending)
        return parlay
    }
    
    func placeParlay(parlay: Parlay, player: Player) {
        let placedParlay = makeParlay(for: parlay.bets)
        player.parlays.append(placedParlay)
    }
}
