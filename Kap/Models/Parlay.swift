//
//  Parlay.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

class Parlay {
    let id: UUID
    let userID: UUID
    let bets: [Bet]
    var totalOdds: Int
    var result: BetResult
    var totalPoints: Int
    var betString: String
    
    init(id: UUID, userID: UUID, bets: [Bet], result: BetResult) {
        self.id = id
        self.userID = userID
        self.bets = bets
        self.totalOdds = calculateParlayOdds(bets: bets)
        self.result = result
        self.totalPoints = calculateParlayPoints(odds: totalOdds, result: result)
        self.betString = bets.map { bet in
            let betOption = bet.game.betOptions.first(where: { $0.id == bet.betOptionID })
            return betOption?.betString ?? "No bet string"
        }.joined(separator: ", ")
    }
}

func calculateParlayOdds(bets: [Bet]) -> Int {
    var totalPayout = 1.0
    for bet in bets {
        let payout: Double
        if bet.odds > 0 {
            payout = 1 + Double(bet.odds) / 100
        } else {
            payout = 1 - 100 / Double(bet.odds)
        }
        totalPayout *= payout
    }

    let parlayOdds: Int
    if totalPayout >= 2 {
        parlayOdds = Int((totalPayout - 1) * 100) // For positive odds
    } else {
        parlayOdds = Int(-100 / (totalPayout - 1)) // For negative odds
    }
    return parlayOdds
}

func calculateParlayPoints(odds: Int, basePoints: Double = 10.0, result: BetResult) -> Int {
    var points: Int = 0
    if result == .win {
        if odds > 0 { // Positive American odds
            points = Int((Double(odds) / 100.0) * basePoints)
        } else { // Negative American odds
            points = Int((100.0 / Double(abs(odds))) * basePoints)
        }
    }
    return points
}
