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
    var parlaySelections: [BetOption] = []
    
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
            var weeks = [Week]()
            
            let week = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 0)
            let week2 = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 1)
            weeks.append(week)
            weeks.append(week2)
            
            season.weeks = weeks
            
            let games = try await GameService().getGames()
            let weeklyGames = games.chunked(into: 16)
            self.games = weeklyGames[0]
            
            for player in league.players {
                let _ = AppDataViewModel().generateRandomBets(from: self.games, betCount: 6, player: player)
            }
            
            self.players = league.players.sorted { $0.points[0] ?? 0 > $1.points[0] ?? 0 }
        } catch {
            print("Failed to get games: \(error)")
        }
        
        return self.players
    }
    
    func createWeek(season: Season, league: League, weekNumber: Int) async -> Week {
        let week = Week(id: UUID(), weekNumber: weekNumber, season: season, games: [], bets: [[]], parlays: [], isComplete: false)
        do {
            let games = try await GameService().getGames()
            week.games = games.chunked(into: 16)[0]
        } catch {
            print("Failed to get games: \(error)")
        }
        
        for player in league.players {
            week.bets.append(generateRandomBets(from: week.games, betCount: 6, player: player))
        }
        
        return week
    }
    
    func generateRandomBets(from games: [Game], betCount: Int, player: Player) -> [Bet] {
        var bets = [Bet]()
        let allBetTypes: [BetType] = [.spread, .moneyline, .over, .under]
        let allBetResults: [BetResult] = [.win, .loss, .pending]
        
        for _ in 0..<betCount {
            if let chosenGame = games.randomElement(),
               let chosenBet = chosenGame.betOptions.randomElement() {
                if let betOption = chosenGame.betOptions.first(where: { $0.id == chosenBet.id }) {
                    let bet = Bet(id: UUID(), userID: player.user.userID, betOptionID: chosenBet.id, game: chosenGame, type: allBetTypes.randomElement()!, result: allBetResults.randomElement()!, odds: chosenBet.odds, selectedTeam: betOption.selectedTeam)
                    bets.append(bet)
                    player.points[currentWeek]! += bet.points!
                }
                
            }
        }
        self.bets = bets
        return bets
    }
    
    func generateRandomNumberInRange(range: ClosedRange<Int>) -> Int {
        return Int.random(in: range)
    }
    
    func createParlayWithinOddsRange(for player: Player, from bets: [Bet]) -> Parlay {
//        let betCount = generateRandomNumberInRange(range: 2...6) // assuming parlays consist of 2-6 bets
//        var parlayBets = generateRandomBets(from: bets, betCount: betCount, player: player)
        
        var parlayOdds = calculateParlayOdds(bets: bets)
        let allBetResults: [BetResult] = [.win, .loss, .pending]
        
//        while parlayOdds < 400 || parlayOdds > 800 {
//            if parlayBets.count <= 2 {
//                // can't create a valid parlay with less than 2 bets
//                return nil
//            }
//            // remove bet with lowest absolute odds and recalculate
//            if let minBet = parlayBets.min(by: { abs($0.odds) < abs($1.odds) }) {
//                parlayBets = parlayBets.filter { $0.id != minBet.id }
//                parlayOdds = calculateParlayOdds(bets: parlayBets)
//            }
//        }
        
        let parlay = Parlay(id: UUID(), userID: player.user.userID, bets: bets, result: allBetResults.randomElement()!)
        player.parlays.append(parlay)
        if parlay.totalPoints != 0 {
            player.points[0]! += parlay.totalPoints
        }
        return parlay
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
}
