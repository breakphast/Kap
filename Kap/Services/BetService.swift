//
//  BetService.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

class BetService {
    var games: [Game] = []
    let viewModel = AppDataViewModel()

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

    func makeBet(for game: Game, betOption: BetOption, player: Player) {
        let bet = Bet(id: UUID(), userID: player.user.userID, betOptionID: betOption.id, game: game, type: betOption.betType, result: .win, odds: betOption.odds)
        player.bets[0].append(bet)
    }
    
    func makeParlay(for games: [Game], player: Player) {
        let parlay = viewModel.createParlayWithinOddsRange(for: player, from: games)
    }
}
