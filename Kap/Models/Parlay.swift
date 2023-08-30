//
//  Parlay.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

class Parlay {
    let id: UUID
    let bets: [Bet]
    var totalOdds: Int
    var result: BetResult
    var totalPoints: Double
    var betString: String?
    var playerID: String
    var week: Int
    
    init(id: UUID, bets: [Bet], totalOdds: Int, result: BetResult, playerID: String, week: Int) {
        self.id = id
        self.bets = bets
        self.totalOdds = totalOdds
        self.result = result
        self.totalPoints = calculateParlayPoints(odds: totalOdds, result: .win)
        self.playerID = playerID
        self.week = week
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

func calculateParlayPoints(odds: Int, basePoints: Double = 10.0, result: BetResult) -> Double {
    var points: Double = 0
    if result == .win {
        if odds > 0 { // Positive American odds
            points = Double((Double(odds) / 100.0) * basePoints)
        } else { // Negative American odds
            points = Double((100.0 / Double(abs(odds))) * basePoints)
        }
    }
    return points
}
