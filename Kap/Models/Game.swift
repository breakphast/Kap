//
//  Game.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

class Game {
    let id: String
    var homeTeam: String
    var awayTeam: String
    var date: Date
    var betOptions = [BetOption]()
    var homeSpread: Double
    var awaySpread: Double
    var homeMoneyLine: Int
    var awayMoneyLine: Int
    var over: Double
    var under: Double
    var completed: Bool
    var homeScore: String?
    var awayScore: String?
    var homeSpreadPriceTemp: Double
    var awaySpreadPriceTemp: Double
    var overPriceTemp: Double
    var underPriceTemp: Double
    
    init(gameElement: GameElement) {
        var homeSpreadTemp: Double = 0.0
        var awaySpreadTemp: Double = 0.0
        var homeMoneyLineTemp: Int = 0
        var awayMoneyLineTemp: Int = 0
        var overTemp: Double = 0.0
        var underTemp: Double = 0.0
        var homeSpreadPriceTemp: Double = 0.0
        var awaySpreadPriceTemp: Double = 0.0
        var overPriceTemp: Double = 0.0
        var underPriceTemp: Double = 0.0

        if let fanduel = gameElement.bookmakers?.first(where: { $0.key == .fanduel }) {
            fanduel.markets.forEach { market in
                switch market.key {
                case .h2H:
                    market.outcomes.forEach { outcome in
                        if outcome.name == gameElement.homeTeam {
                            homeMoneyLineTemp = outcome.price
                        } else if outcome.name == gameElement.awayTeam {
                            awayMoneyLineTemp = outcome.price
                        }
                    }
                case .spreads:
                    market.outcomes.forEach { outcome in
                        if outcome.name == gameElement.homeTeam {
                            homeSpreadTemp = outcome.point ?? 0.0
                            homeSpreadPriceTemp = Double(outcome.price)
                        } else if outcome.name == gameElement.awayTeam {
                            awaySpreadTemp = outcome.point ?? 0.0
                            awaySpreadPriceTemp = Double(outcome.price)
                        }
                    }
                case .totals:
                    market.outcomes.forEach { outcome in
                        if outcome.name == "Over" {
                            overTemp = outcome.point ?? 0.0
                            overPriceTemp = Double(outcome.price)
                        } else if outcome.name == "Under" {
                            underTemp = outcome.point ?? 0.0
                            underPriceTemp = Double(outcome.price)
                        }
                    }
                }
            }
        }
        
        // Initializing properties
        self.id = gameElement.id
        self.homeTeam = gameElement.homeTeam
        self.awayTeam = gameElement.awayTeam
        self.date = gameElement.commenceTime
        self.homeMoneyLine = homeMoneyLineTemp
        self.awayMoneyLine = awayMoneyLineTemp
        self.homeSpread = homeSpreadTemp
        self.awaySpread = awaySpreadTemp
        self.over = overTemp
        self.under = underTemp
        self.completed = gameElement.completed ?? false
        if let scores = gameElement.scores {
            for score in scores {
                if score.name == self.homeTeam {
                    self.homeScore = score.score
                } else if score.name == self.awayTeam {
                    self.awayScore = score.score
                }
            }
        }
        self.homeSpreadPriceTemp = homeSpreadPriceTemp
        self.awaySpreadPriceTemp = awaySpreadPriceTemp
        self.overPriceTemp = overPriceTemp
        self.underPriceTemp = underPriceTemp
        self.betOptions = createBetOptions()
    }
    
    func createBetOptions() -> [BetOption] {
        let homeSpreadBet = BetOption(game: self, betType: .spread, odds: Int(homeSpreadPriceTemp), spread: homeSpread, over: over, under: under, selectedTeam: homeTeam)
        let awaySpreadBet = BetOption(game: self, betType: .spread, odds: Int(awaySpreadPriceTemp), spread: awaySpread, over: over, under: under, selectedTeam: awayTeam)
        let homeMoneyLineBet = BetOption(game: self, betType: .moneyline, odds: homeMoneyLine, over: over, under: under, selectedTeam: homeTeam)
        let awayMoneyLineBet = BetOption(game: self, betType: .moneyline, odds: awayMoneyLine, over: over, under: under, selectedTeam: awayTeam)
        let overBet = BetOption(game: self, betType: .over, odds: Int(overPriceTemp), over: over, under: under, selectedTeam: homeTeam)
        let underBet = BetOption(game: self, betType: .under, odds: Int(underPriceTemp), over: over, under: under, selectedTeam: homeTeam)
        
        return [homeSpreadBet, awaySpreadBet, homeMoneyLineBet, awayMoneyLineBet, overBet, underBet]
    }
}



// MARK: - GameElement
struct GameElement: Codable {
    let id: String
    let sportKey: SportKey
    let sportTitle: SportTitle
    let commenceTime: Date
    let completed: Bool?
    let homeTeam, awayTeam: String
    let bookmakers: [Bookmaker]?
    let scores: [Score]?

    enum CodingKeys: String, CodingKey {
        case id
        case sportKey = "sport_key"
        case sportTitle = "sport_title"
        case commenceTime = "commence_time"
        case completed
        case homeTeam = "home_team"
        case awayTeam = "away_team"
        case bookmakers
        case scores
    }
}

struct Score: Codable {
    let name: String
    let score: String
}

// MARK: - Bookmaker
struct Bookmaker: Codable {
    let key: BookmakerKey
    let title: Title
    let lastUpdate: Date
    let markets: [Market]

    enum CodingKeys: String, CodingKey {
        case key, title
        case lastUpdate = "last_update"
        case markets
    }
}

enum BookmakerKey: String, Codable {
    case fanduel = "fanduel"
}

// MARK: - Market
struct Market: Codable {
    let key: MarketKey
    let lastUpdate: Date
    let outcomes: [Outcome]

    enum CodingKeys: String, CodingKey {
        case key
        case lastUpdate = "last_update"
        case outcomes
    }
}

enum MarketKey: String, Codable {
    case h2H = "h2h"
    case spreads = "spreads"
    case totals = "totals"
}

// MARK: - Outcome
struct Outcome: Codable {
    let name: String
    let price: Int
    let point: Double?
}

enum Title: String, Codable {
    case fanDuel = "FanDuel"
}

enum SportKey: String, Codable {
    case football_nfl = "football_nfl"
}

enum SportTitle: String, Codable {
    case NFL = "NFL"
}
