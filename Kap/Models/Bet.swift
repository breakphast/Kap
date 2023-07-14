//
//  Bet.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

enum BetType: String {
    case spread = "Spread"
    case moneyline = "Moneyline"
    case over = "Over"
    case under = "Under"
}
enum BetResult: String {
    case win = "Win"
    case loss = "Loss"
    case push = "Push"
    case pending = "Pending"
}

struct BetOption {
    let id: UUID
    let gameID: String
    let betType: BetType
    var odds: Int
    var spread: Double?
    var over: Double
    var under: Double
    var betString: String
    var selectedTeam: String?

    init(gameID: String, betType: BetType, odds: Int, spread: Double? = nil, over: Double, under: Double, selectedTeam: String? = nil) {
        self.id = UUID()
        self.gameID = gameID
        self.betType = betType
        self.odds = odds
        self.spread = spread
        self.over = over
        self.under = under
        self.selectedTeam = selectedTeam

        let formattedOdds = odds > 0 ? "+\(odds)" : "\(odds)"

        switch betType {
        case .spread:
            if let spread = spread {
                let formattedSpread = spread > 0 ? "+\(spread)" : "\(spread)"
                betString = "\(formattedSpread) \(formattedOdds)"
            } else {
                betString = ""
            }
        case .moneyline:
            betString = formattedOdds
        case .over:
            betString = "O\(over) \(formattedOdds)"
        case .under:
            betString = "U\(under) \(formattedOdds)"
        }
        
        if betType == .spread || betType == .moneyline {
            if let selectedTeam = selectedTeam {
                betString = "\(selectedTeam) \(betString)"
            }
        }
    }
}

struct Bet {
    let id: UUID
    let userID: UUID
    let betOptionID: UUID
    let game: Game
    let type: BetType
    let result: BetResult?
    let odds: Int
    var points: Int?
    let stake = 100.0
    
    init(id: UUID, userID: UUID, betOptionID: UUID, game: Game, type: BetType, result: BetResult?, odds: Int) {
        self.id = id
        self.userID = userID
        self.betOptionID = betOptionID
        self.game = game
        self.type = type
        self.result = result
        self.odds = odds
        self.points = calculatePoints(bet: self)
    }
    
    func calculatePoints(bet: Bet, basePoints: Int = 10) -> Int {
        var points: Double
        
        if bet.odds > 0 { // Positive American odds
            points = Double(bet.odds) / 100.0 * Double(basePoints)
        } else { // Negative American odds
            points = 100.0 / Double(abs(bet.odds)) * Double(basePoints)
        }
        return bet.result == .win ? Int(round(points)) : Int(round(-points)) / 2
    }
}
