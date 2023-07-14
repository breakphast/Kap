//
//  AppDataViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI

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
    
    init() {
        Task {
            do {
                let games = try await GameService().getGames()
                weeklyGames = games.chunked(into: 16)
                self.games = weeklyGames[0]
            } catch {
                print("Failed to get games: \(error)")
            }
        }
        
        self.users = [
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "ThePhast", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "RingoMingo", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Harch", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Brokeee", leagues: [])
        ]
    }
    
    func goTest() async -> Week {
        let league = createLeague(name: "BIG JOHN SILVER", players: [])
        let week = await createWeek(season: createSeason(league: league, year: 2023), league: league, weekNumber: 0)
        
        return week
    }
    
    func createWeek(season: Season, league: League, weekNumber: Int) async -> Week {
        let week = Week(id: UUID(), season: season, games: [], bets: [[]], parlays: [], isComplete: false)
        do {
            let games = try await GameService().getGames()
            week.games = games.chunked(into: 16)[weekNumber]
        } catch {
            print("Failed to get games: \(error)")
        }
        
        for player in league.players {
            week.bets.append(generateRandomBets(from: week.games, betCount: 6, player: player))
            
            if let parlay = createParlayWithinOddsRange(for: player, from: week.games) {
                week.parlays.append(parlay)
            }
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
                let bet = Bet(id: UUID(), userID: player.user.userID, betOptionID: chosenBet.id, game: chosenGame, type: allBetTypes.randomElement()!, result: allBetResults.randomElement()!, odds: chosenBet.odds)
                bets.append(bet)
            }
        }
        
        return bets
    }
    
    func generateRandomNumberInRange(range: ClosedRange<Int>) -> Int {
        return Int.random(in: range)
    }
    
    func createParlayWithinOddsRange(for player: Player, from games: [Game]) -> Parlay? {
        let betCount = generateRandomNumberInRange(range: 2...6) // assuming parlays consist of 2-6 bets
        var parlayBets = generateRandomBets(from: games, betCount: betCount, player: player)
        var parlayOdds = calculateParlayOdds(bets: parlayBets)
        let allBetResults: [BetResult] = [.win, .loss, .pending]
        
        while parlayOdds < 400 || parlayOdds > 1000 {
            if parlayBets.count <= 2 {
                // can't create a valid parlay with less than 2 bets
                return nil
            }
            // remove bet with lowest absolute odds and recalculate
            if let minBet = parlayBets.min(by: { abs($0.odds) < abs($1.odds) }) {
                parlayBets = parlayBets.filter { $0.id != minBet.id }
                parlayOdds = calculateParlayOdds(bets: parlayBets)
            }
        }
        
        return Parlay(id: UUID(), userID: player.user.userID, bets: parlayBets, result: allBetResults.randomElement()!)
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
