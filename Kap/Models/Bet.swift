//
//  Bet.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation
import SwiftUI

class BetOption {
    let id: String
    let game: Game
    let betType: BetType
    var odds: Int
    var spread: Double?
    var over: Double
    var under: Double
    var betString: String
    var selectedTeam: String?
    var confirmBet: Bool
    var maxBets: Int?
    
    init(id: String, game: Game, betType: BetType, odds: Int, spread: Double? = nil, over: Double, under: Double, selectedTeam: String? = nil, confirmBet: Bool = false) {
        self.id = id
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
    let id: String
    let betOption: String
    let game: GameModel
    let type: BetType
    let result: BetResult?
    let odds: Int
    var points: Double?
    let stake = 100.0
    var betString: String
    let selectedTeam: String?
    let playerID: String
    var week: Int
    let leagueCode: String
    var betOptionString = ""
    let timestamp: Date?
    let deletedTimestamp: Date?
    let isDeleted: Bool?
    
    init(id: String, betOption: String, game: GameModel, type: BetType, result: BetResult?, odds: Int, selectedTeam: String?, playerID: String, week: Int, leagueCode: String, timestamp: Date?, deletedTimestamp: Date?, isDeleted: Bool?) {
        self.id = id
        self.betOption = betOption
        self.game = game
        self.type = type
        self.result = result
        self.odds = odds
        self.selectedTeam = selectedTeam
        self.playerID = playerID
        self.week = week
        self.leagueCode = leagueCode
        self.timestamp = timestamp
        self.deletedTimestamp = deletedTimestamp
        self.isDeleted = isDeleted
        
        let formattedOdds = odds > 0 ? "+\(odds)" : "\(odds)"
        let spread = selectedTeam == game.homeTeam ? game.homeSpread : game.awaySpread
        let formattedSpread = spread > 0 ? "+\(spread)" : "\(spread)"
        
        switch type {
        case .spread:
            self.betString = formattedSpread
            betOptionString = betString + "\n\(formattedOdds)"
            
        case .moneyline:
            self.betString = "\(selectedTeam ?? "") ML"
            betOptionString = formattedOdds

        case .over:
            self.betString = "O\(game.over)"
            betOptionString = "O \(game.over)\n\(formattedOdds)"
        case .under:
            self.betString = "U\(game.under)"
            betOptionString = "U \(game.under)\n\(formattedOdds)"
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
            points = -10
        }
        
        return points
    }
    
    func checkBetResult(bet: Bet) -> BetResult {
        guard let homeScore = Int(bet.game.homeScore ?? ""), let awayScore = Int(bet.game.awayScore ?? "") else {
            return .pending
        }
        
        guard let betOptionsSet = bet.game.betOptions,
              let betOptionsArray = betOptionsSet.allObjects as? [BetOption],
              let betOption = betOptionsArray.first(where: { $0.id == bet.betOption }),
              let selectedTeam = betOption.selectedTeam else {
            return .pending
        }
        
        switch bet.type {
        case .moneyline:
            guard homeScore != awayScore else { return .push }
            
            if selectedTeam == bet.game.homeTeam {
                return homeScore > awayScore ? .win : .loss
            } else if selectedTeam == bet.game.awayTeam {
                return awayScore > homeScore ? .win : .loss
            }
            
        case .spread:
            let spread = betOption.spread ?? 0.0
            if selectedTeam == bet.game.homeTeam {
                return Double(homeScore) + spread > Double(awayScore) ? .win : .loss
            } else if selectedTeam == bet.game.awayTeam {
                return Double(awayScore) + spread > Double(homeScore) ? .win : .loss
            }
            
        case .over:
            let over = betOption.over
            return Double(homeScore + awayScore) > over ? .win : .loss
            
        case .under:
            let under = betOption.under
            return Double(homeScore + awayScore) < under ? .win : .loss
        }
        
        return .pending
    }
}


extension BetOption {
    var dictionary: [String: Any] {
        return [
            "id": id,
            "betType": betType.rawValue,
            "odds": odds,
            "spread": spread ?? NSNull(),
            "over": over,
            "under": under,
            "selectedTeam": selectedTeam ?? NSNull(),
            "confirmBet": confirmBet,
            "betString": betString,
            "maxBets": maxBets ?? NSNull()
        ]
    }
    
    static func fromDictionary(_ dictionary: [String: Any], game: Game) -> BetOption? {
        guard
            let id = dictionary["id"] as? String,
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
        
        let betOption = BetOption(id: id, game: game, betType: betType, odds: odds, spread: spread, over: over, under: under, selectedTeam: selectedTeam, confirmBet: confirmBet)
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

extension Double {
    var twoDecimalString: String {
        return String(format: "%.2f", self)
    }
    var oneDecimalString: String {
        return String(format: "%.1f", self)
    }
    var noDecimalString: String {
        return String(format: "%.0f", self)
    }
}
