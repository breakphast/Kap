//
//  AppDataViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI
import Observation

@Observable class AppDataViewModel {
    var users: [User] = []
    var leagues: [League] = []
    var seasons: [Season] = []
    var weeks: [Week] = []
    var players: [Player] = []
    var games: [Game] = []
    var bets: [Bet] = []
    var parlays: [Parlay] = []
    var weeklyGames: [[Game]] = [[]]
    var currentWeek = 0
    var activeButtons: [UUID] = []
    var selectedBets: [Bet] = []
    var activeParlays: [Parlay] = []
    var currentPlayer: Player?
    
    init() {
        self.users = [
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "ThePhast", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "RingoMingo", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Harch", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Brokeee", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Mingy", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "HeyHey", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Ralph Lawrence", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Rakes", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "PolioIt", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Bandszs", leagues: [])
        ]
    }
    
    func getLeaderboardData() async -> [Player] {
        do {
            let league = AppDataViewModel().createLeague(name: "BIG JOHN SILVER", players: [])
            let season = AppDataViewModel().createSeason(league: league, year: 2023)
            let week = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 0)
            let week2 = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 1)
            weeks.append(week)
            weeks.append(week2)
                        
            games = try await GameService().getGames()
            
            weeks[0].games = games
            updateDayType(for: &weeks[0].games)
            
            players = league.players.sorted { $0.points[0] ?? 0 > $1.points[0] ?? 0 } // leaderboard sorting
            self.currentPlayer = players[0]
        } catch {
            print("Failed to get games: \(error)")
        }
        
        return self.players
    }
    
    func updateDayType(for games: inout [Game]) {
        for game in games.prefix(1) {
            game.betOptions = game.betOptions.map { bet in
                let mutableBet = bet
                mutableBet.dayType = .tnf
                mutableBet.maxBets = 1
                return mutableBet
            }
        }
        
        let sundayAfternoonGamesCount = games.count - 3
        for game in games.dropFirst().prefix(sundayAfternoonGamesCount) {
            game.betOptions = game.betOptions.map { bet in
                let mutableBet = bet
                mutableBet.dayType = .sunday
                mutableBet.maxBets = 3
                return mutableBet
            }
        }
        
        for game in games.dropFirst(sundayAfternoonGamesCount + 1).prefix(1) {
            game.betOptions = game.betOptions.map { bet in
                let mutableBet = bet
                mutableBet.dayType = .snf
                mutableBet.maxBets = 1
                return mutableBet
            }
        }
        
        for game in games.suffix(1) {
            game.betOptions = game.betOptions.map { bet in
                let mutableBet = bet
                mutableBet.dayType = .mnf
                mutableBet.maxBets = 1
                return mutableBet
            }
        }
    }

    func generateBetsForGame(_ game: Game) -> [Bet] {
        var bets = [Bet]()
        let options = [0, 2, 4, 1, 3, 5].compactMap { index in
            game.betOptions.indices.contains(index) ? game.betOptions[index] : nil
        }
        for i in 0..<6 {
            var type = BetType.moneyline
            switch i {
            case 0, 3:
                type = .spread
            case 1, 4:
                type = .moneyline
            case 2:
                type = .over
            case 5:
                type = .under
            default:
                type = .moneyline
            }
            var team = ""
            switch i {
            case 0, 2, 4:
                team = game.awayTeam
            default:
                team = game.homeTeam
            }
            
            let bet = Bet(id: UUID(), betOption: options[i], game: game, type: type, result: .pending, odds: options[i].odds, selectedTeam: team)
            bets.append(bet)
        }
        self.bets = bets
        let betss = [0, 4, 2, 3, 1, 5].compactMap { index in
            bets.indices.contains(index) ? bets[index] : nil
        }
        
        return betss
    }
    
    func generateRandomNumberInRange(range: ClosedRange<Int>) -> Int {
        return Int.random(in: range)
    }
    
    func createLeague(name: String, players: [Player]) -> League {
        let league = League(leagueID: UUID(), name: name, dateCreated: Date(), currentSeason: 2023, seasons: [], players: [])
        league.players = createPlayers(users: users, league: league)
        return league
    }
    
    func createSeason(league: League, year: Int) -> Season {
        let season = Season(id: UUID(), league: league, year: year, weeks: [])
        return season
    }
    
    func createPlayers(users: [User], league: League) -> [Player] {
        var players = [Player]()
        
        for user in users {
            let player = Player(id: user.userID, user: user, league: league, name: user.name, bets: [[]], parlays: [], points: [:])
            players.append(player)
        }
        return players
    }
    
    
    func createWeek(season: Season, league: League, weekNumber: Int) async -> Week {
        let week = Week(id: UUID(), weekNumber: weekNumber, season: season, games: [], bets: [[]], parlays: [], isComplete: false)
        //        do {
        //            let games = try await GameService().getGames()
        //            week.games = games.chunked(into: 16)[0]
        //        } catch {
        //            print("Failed to get games: \(error)")
        //        }
        
        //        for _ in league.players {
        //            week.bets.append(generateRandomBets(from: week.games, betCount: 6))
        //        }
        
        return week
    }
}
