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
    let betString: String
    
    init(id: UUID, userID: UUID, betOptionID: UUID, game: Game, type: BetType, result: BetResult?, odds: Int) {
        self.id = id
        self.userID = userID
        self.betOptionID = betOptionID
        self.game = game
        self.type = type
        self.result = result
        self.odds = odds
        self.betString = game.betOptions.first { $0.id == betOptionID }?.betString ?? ""
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
        let selectedTeam = bet.game.betOptions.first(where: { $0.id == bet.betOptionID })?.selectedTeam
        
        switch bet.type {
        case .moneyline:
            guard homeScore != awayScore else { return .push }
            
            if selectedTeam == bet.game.homeTeam {
                return homeScore > awayScore ? .win : .loss
            } else if selectedTeam == bet.game.awayTeam {
                return homeScore < awayScore ? .win : .loss
            }
        case .spread:
            let spread = bet.game.betOptions.first(where: { $0.id == bet.betOptionID })?.spread ?? 0.0
            if selectedTeam == bet.game.homeTeam {
                return Double(homeScore) + spread > Double(awayScore) ? .win : .loss
            } else if selectedTeam == bet.game.awayTeam {
                return Double(awayScore) + spread > Double(homeScore) ? .win : .loss
            }
        case .over:
            let over = bet.game.betOptions.first(where: { $0.id == bet.betOptionID })?.over ?? 0.0
            return Double(homeScore + awayScore) > over ? .win : .loss
        case .under:
            let under = bet.game.betOptions.first(where: { $0.id == bet.betOptionID })?.under ?? 0.0
            return Double(homeScore + awayScore) < under ? .win : .loss
        }
        
        return .pending
    }
}
