//
//  Bet.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation
import SwiftUI

class BetOption {
    var id: UUID
    let game: Game
    let betType: BetType
    var odds: Int
    var spread: Double?
    var over: Double
    var under: Double
    var betString: String
    var selectedTeam: String?
    var confirmBet: Bool
    var dayType: DayType?
    var maxBets: Int?
    
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

class Bet {
    let id: UUID
    let betOption: BetOption
    let game: Game
    let type: BetType
    let result: BetResult?
    let odds: Int
    var points: Double?
    let stake = 100.0
    let betString: String
    let selectedTeam: String?
    let playerID: String
    var week: Int
    
    init(id: UUID, betOption: BetOption, game: Game, type: BetType, result: BetResult?, odds: Int, selectedTeam: String?, playerID: String, week: Int) {
        self.id = id
        self.betOption = betOption
        self.game = game
        self.type = type
        self.result = result
        self.odds = odds
        self.selectedTeam = selectedTeam
        self.playerID = playerID
        self.week = week
        
        switch type {
        case .spread:
            if let spread = betOption.spread {
                let formattedSpread = spread > 0 ? "+\(spread)" : "\(spread)"
                betString = "\(formattedSpread)"
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
    
    func calculatePoints(bet: Bet, basePoints: Double = 10) -> Double {
        var points: Double
        
        if bet.odds > 0 { // Positive American odds
            points = Double(bet.odds) / 100.0 * Double(basePoints)
        } else if bet.odds < 0 { // Negative American odds
            points = 100.0 / Double(abs(bet.odds)) * Double(basePoints)
        } else {
            return 0
        }
        
        if bet.result == .loss {
            points *= -1
            points = points / 2
        }
        
        return points
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


extension BetOption {
    var dictionary: [String: Any] {
        return [
            "id": id.uuidString,
            "betType": betType.rawValue,
            "odds": odds,
            "spread": spread ?? NSNull(),
            "over": over,
            "under": under,
            "selectedTeam": selectedTeam ?? NSNull(),
            "confirmBet": confirmBet,
            "betString": betString,
            "dayType": dayType?.rawValue ?? NSNull(),
            "maxBets": maxBets ?? NSNull()
        ]
    }
    
    static func fromDictionary(_ dictionary: [String: Any], game: Game) -> BetOption? {
        guard
            let idString = dictionary["id"] as? String,
            let id = UUID(uuidString: idString),
            let betTypeString = dictionary["betType"] as? String,
            let betType = BetType(rawValue: betTypeString),
            let odds = dictionary["odds"] as? Int,
            let over = dictionary["over"] as? Double,
            let under = dictionary["under"] as? Double
        else {
            return nil
        }
        
        let spread = dictionary["spread"] as? Double
        let selectedTeam = dictionary["selectedTeam"] as? String
        let confirmBet = dictionary["confirmBet"] as? Bool ?? false
        let dayTypeString = dictionary["dayType"] as? String
        
        let betOption = BetOption(game: game, betType: betType, odds: odds, spread: spread, over: over, under: under, selectedTeam: selectedTeam, confirmBet: confirmBet)
        betOption.id = id
        return betOption
    }
}

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

enum DayType: String {
    case tnf = "TNF"
    case sunday = "SUN"
    case snf = "SNF"
    case mnf = "MNF"
    case parlay = "PARLAY BONUS"
}

extension Double {
    var oneDecimalString: String {
        return String(format: "%.1f", self)
    }
}
