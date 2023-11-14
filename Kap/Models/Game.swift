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
    var week: Int?
    
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
        self.completed = false
        if let scores = gameElement.scores {
            self.homeScore = scores[0].score
            self.awayScore = scores[1].score
        }
        self.homeSpreadPriceTemp = homeSpreadPriceTemp
        self.awaySpreadPriceTemp = awaySpreadPriceTemp
        self.overPriceTemp = overPriceTemp
        self.underPriceTemp = underPriceTemp
        self.week = Game.nflWeek(for: gameElement.commenceTime) ?? 0
        self.betOptions = createBetOptions()
    }
    
    static let nflWeekSchedule: [NFLWeek] = [
        NFLWeek(weekNumber: 1, startDate: Date.fromString("2023-09-07")!, endDate: Date.fromString("2023-09-13")!),
        NFLWeek(weekNumber: 2, startDate: Date.fromString("2023-09-14")!, endDate: Date.fromString("2023-09-20")!),
        NFLWeek(weekNumber: 3, startDate: Date.fromString("2023-09-21")!, endDate: Date.fromString("2023-09-27")!),
        NFLWeek(weekNumber: 4, startDate: Date.fromString("2023-09-28")!, endDate: Date.fromString("2023-10-04")!),
        NFLWeek(weekNumber: 5, startDate: Date.fromString("2023-10-05")!, endDate: Date.fromString("2023-10-11")!),
        NFLWeek(weekNumber: 6, startDate: Date.fromString("2023-10-12")!, endDate: Date.fromString("2023-10-18")!),
        NFLWeek(weekNumber: 7, startDate: Date.fromString("2023-10-19")!, endDate: Date.fromString("2023-10-25")!),
        NFLWeek(weekNumber: 8, startDate: Date.fromString("2023-10-26")!, endDate: Date.fromString("2023-11-01")!),
        NFLWeek(weekNumber: 9, startDate: Date.fromString("2023-11-02")!, endDate: Date.fromString("2023-11-08")!),
        NFLWeek(weekNumber: 10, startDate: Date.fromString("2023-11-09")!, endDate: Date.fromString("2023-11-15")!),
        NFLWeek(weekNumber: 11, startDate: Date.fromString("2023-11-16")!, endDate: Date.fromString("2023-11-22")!),
        NFLWeek(weekNumber: 12, startDate: Date.fromString("2023-11-23")!, endDate: Date.fromString("2023-11-29")!),
        NFLWeek(weekNumber: 13, startDate: Date.fromString("2023-11-30")!, endDate: Date.fromString("2023-12-06")!),
        NFLWeek(weekNumber: 14, startDate: Date.fromString("2023-12-07")!, endDate: Date.fromString("2023-12-13")!),
        NFLWeek(weekNumber: 15, startDate: Date.fromString("2023-12-14")!, endDate: Date.fromString("2023-12-20")!),
        NFLWeek(weekNumber: 16, startDate: Date.fromString("2023-12-21")!, endDate: Date.fromString("2023-12-27")!),
        NFLWeek(weekNumber: 17, startDate: Date.fromString("2023-12-28")!, endDate: Date.fromString("2024-01-03")!),
        NFLWeek(weekNumber: 18, startDate: Date.fromString("2024-01-04")!, endDate: Date.fromString("2024-01-10")!)
    ]


    static func nflWeek(for date: Date) -> Int? {
        for week in nflWeekSchedule {
            if date >= week.startDate && date <= week.endDate {
                return week.weekNumber
            }
        }
        return nil  // return nil if the date does not fall within any NFL week
    }
    
    func createBetOptions() -> [BetOption] {
        let homeSpreadBet = BetOption(id: self.documentId + "spread1", game: self, betType: .spread, odds: Int(homeSpreadPriceTemp), spread: homeSpread, over: over, under: under, selectedTeam: homeTeam)
        let awaySpreadBet = BetOption(id: self.documentId + "spread2", game: self, betType: .spread, odds: Int(awaySpreadPriceTemp), spread: awaySpread, over: over, under: under, selectedTeam: awayTeam)
        let homeMoneyLineBet = BetOption(id: self.documentId + "ml1", game: self, betType: .moneyline, odds: homeMoneyLine, over: over, under: under, selectedTeam: homeTeam)
        let awayMoneyLineBet = BetOption(id: self.documentId + "ml2", game: self, betType: .moneyline, odds: awayMoneyLine, over: over, under: under, selectedTeam: awayTeam)
        let overBet = BetOption(id: self.documentId + "over", game: self, betType: .over, odds: Int(overPriceTemp), over: over, under: under, selectedTeam: homeTeam)
        let underBet = BetOption(id: self.documentId + "under", game: self, betType: .under, odds: Int(underPriceTemp), over: over, under: under, selectedTeam: homeTeam)
        
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
    let score: String?
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

struct NFLWeek {
    let weekNumber: Int
    let startDate: Date
    let endDate: Date
}

enum Title: String, Codable {
    case fanDuel = "FanDuel"
}

enum SportKey: String, Codable {
    case americanfootball_nfl = "americanfootball_nfl"
    case baseball_mlb = "baseball_mlb"
}

enum SportTitle: String, Codable {
    case NFL = "NFL"
    case MLB = "MLB"
}

extension Game {
    func betResult(for bet: Bet) -> BetResult {
        guard completed, let homeScore = self.homeScore, let awayScore = self.awayScore else {
            return .pending
        }
        switch bet.type {
        case .moneyline:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            if bet.selectedTeam == homeTeam {
                return homeIntScore > awayIntScore ? .win : .loss
            } else {
                return awayIntScore > homeIntScore ? .win : .loss
            }
            
        case .spread:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            let resultScore: Int
            if bet.selectedTeam == awayTeam {
                resultScore = homeIntScore - awayIntScore
            } else {
                resultScore = awayIntScore - homeIntScore
            }

            if Double(abs(resultScore)) < abs(self.homeSpread) {
                return .win
            } else if Double(resultScore) > abs(self.homeSpread) {
                return .loss
            } else {
                return .push
            }

            
        case .over:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            return Double(homeIntScore + awayIntScore) > bet.game.over ? .win : .loss
            
        case .under:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            return Double(homeIntScore + awayIntScore) < bet.game.under ? .win : .loss
        }
    }
}

extension GameModel {
    func betResult(for bet: BetModel) -> BetResult {
        guard completed, let homeScore = self.homeScore, let awayScore = self.awayScore else {
            return .pending
        }
        switch bet.type {
        case BetType.moneyline.rawValue:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            if bet.selectedTeam == homeTeam {
                return homeIntScore > awayIntScore ? .win : .loss
            } else {
                return awayIntScore > homeIntScore ? .win : .loss
            }
            
        case BetType.spread.rawValue:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            let spread: Double
            if bet.selectedTeam == homeTeam {
                spread = self.homeSpread
                // -3.5
            } else {
                spread = self.awaySpread
                // +3.5
            }
            
            let resultScore = homeIntScore - awayIntScore
            // 16 - 13 = 3
            
            if Double(resultScore) < spread {
                // 3 < -3 .. NO
                return .win
            } else if Double(resultScore) > spread {
                // 3 > -3 .. NO
                return .loss
            } else {
                // 3 == -3 ... YES
                return .push
            }

            
        case BetType.over.rawValue:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            return Double(homeIntScore + awayIntScore) > bet.game.over ? .win : .loss
            
        case BetType.under.rawValue:
            guard let homeIntScore = Int(homeScore), let awayIntScore = Int(awayScore) else { return .pending }
            
            return Double(homeIntScore + awayIntScore) < bet.game.under ? .win : .loss
        default:
            return .pending
        }
    }
}

extension Date {
    static func fromString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
