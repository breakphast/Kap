//
//  Bet.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation
import SwiftUI
import Observation

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

@Observable class BetOption {
    let id: UUID
    let game: Game
    let betType: BetType
    var odds: Int
    var spread: Double?
    var over: Double
    var under: Double
    var betString: String
    var selectedTeam: String?
    var confirmBet: Bool
    
    init(game: Game, betType: BetType, odds: Int, spread: Double? = nil, over: Double, under: Double, selectedTeam: String? = nil, confirmBet: Bool = false) {
        self.id = UUID()
        self.game = game
        self.betType = betType
        self.odds = odds
        self.spread = spread
        self.over = over
        self.under = under
        self.selectedTeam = selectedTeam
        self.confirmBet = confirmBet
        
        let formattedOdds = odds > 0 ? "+\(odds)" : "\(odds)"
        
        switch betType {
        case .spread:
            if let spread = spread {
                let formattedSpread = spread > 0 ? "+\(spread)" : "\(spread)"
                betString = "\(formattedSpread)\n\(formattedOdds)"
            } else {
                betString = ""
            }
        case .moneyline:
            betString = formattedOdds
        case .over:
            betString = "O \(over)\n\(formattedOdds)"
        case .under:
            betString = "U \(under)\n\(formattedOdds)"
        }
    }
}

@Observable class Bet {
    let id: UUID
    let betOption: BetOption
    let game: Game
    let type: BetType
    let result: BetResult?
    let odds: Int
    var points: Int?
    let stake = 100.0
    let betString: String
    let selectedTeam: String?
    
    init(id: UUID, betOption: BetOption, game: Game, type: BetType, result: BetResult?, odds: Int, selectedTeam: String?) {
        self.id = id
        self.betOption = betOption
        self.game = game
        self.type = type
        self.result = result
        self.odds = odds
        self.selectedTeam = selectedTeam
        
        let formattedOdds = odds > 0 ? "+\(odds)" : "\(odds)"
        
        switch type {
        case .spread:
            if let spread = betOption.spread {
                let formattedSpread = spread > 0 ? "+\(spread)" : "\(spread)"
                betString = "\(selectedTeam ?? "") \(formattedSpread)"
            } else {
                betString = ""
            }
        case .moneyline:
            betString = "\(selectedTeam ?? "") ML"
        case .over:
            betString = "\(betOption.game.awayTeam) @ \(betOption.game.homeTeam) O\(betOption.over)"
        case .under:
            betString = "\(betOption.game.awayTeam) @ \(betOption.game.homeTeam) U\(betOption.under)"
        }
        
        self.points = calculatePoints(bet: self)
    }
    
    func calculatePoints(bet: Bet, basePoints: Int = 10) -> Int {
        var points: Double
        
        if bet.odds > 0 { // Positive American odds
            points = Double(bet.odds) / 100.0 * Double(basePoints)
        } else if bet.odds < 0 { // Negative American odds
            points = 100.0 / Double(abs(bet.odds)) * Double(basePoints)
        } else {
            return 0
        }
        return bet.result == .win ? Int(round(points)) : Int(round(-points)) / 2
    }
    
    func checkBetResult(bet: Bet) -> BetResult {
        guard let homeScore = Int(bet.game.homeScore ?? ""), let awayScore = Int(bet.game.awayScore ?? "") else {
            return .pending
        }
        
        guard let betOption = bet.game.betOptions.first(where: { $0.id == betOption.id }), let selectedTeam = betOption.selectedTeam else {
            return .pending
        }
        
        switch bet.type {
        case .moneyline:
            guard homeScore != awayScore else { return .push }
            
            if selectedTeam == bet.game.homeTeam {
                return homeScore > awayScore ? .win : .loss
            } else if selectedTeam == bet.game.awayTeam {
                return homeScore < awayScore ? .win : .loss
            }
        case .spread:
            let spread = bet.game.betOptions.first(where: { $0.id == betOption.id })?.spread ?? 0.0
            if selectedTeam == bet.game.homeTeam {
                return Double(homeScore) + spread > Double(awayScore) ? .win : .loss
            } else if selectedTeam == bet.game.awayTeam {
                return Double(awayScore) + spread > Double(homeScore) ? .win : .loss
            }
        case .over:
            let over = bet.game.betOptions.first(where: { $0.id == betOption.id })?.over ?? 0.0
            return Double(homeScore + awayScore) > over ? .win : .loss
        case .under:
            let under = bet.game.betOptions.first(where: { $0.id == betOption.id })?.under ?? 0.0
            return Double(homeScore + awayScore) < under ? .win : .loss
        }
        
        return .pending
    }
}
