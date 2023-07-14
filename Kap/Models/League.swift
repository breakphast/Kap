//
//  League.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

class League {
    let leagueID: UUID
    var name: String
    var dateCreated: Date
    var currentSeason: Int
    var seasons: [Season]
    var players: [Player]
    
    init(leagueID: UUID, name: String, dateCreated: Date, currentSeason: Int, seasons: [Season], players: [Player]) {
        self.leagueID = leagueID
        self.name = name
        self.dateCreated = dateCreated
        self.currentSeason = currentSeason
        self.seasons = seasons
        self.players = players
    }
}

class Season {
    let id: UUID
    let league: League
    let year: Int
    var weeks: [Week]
    
    init(id: UUID, league: League, year: Int, weeks: [Week]) {
        self.id = id
        self.league = league
        self.year = year
        self.weeks = weeks
    }
}

class Week {
    let id: UUID
    let weekNumber: Int
    let season: Season
    var games: [Game]
    var bets: [[Bet]]
    var parlays: [Parlay]
    var isComplete: Bool
    
    init(id: UUID, weekNumber: Int, season: Season, games: [Game], bets: [[Bet]], parlays: [Parlay], isComplete: Bool) {
        self.id = id
        self.weekNumber = weekNumber
        self.season = season
        self.games = games
        self.bets = bets
        self.parlays = parlays
        self.isComplete = isComplete
    }
}

class Player {
    let id: UUID
    let user: User
    let league: League
    var name: String
    var bets: [[Bet]]
    var parlays: [Parlay]
    var points: [Int: Int]
    
    init(id: UUID, user: User, league: League, name: String, bets: [[Bet]], parlays: [Parlay], points: [Int: Int]) {
        self.id = id
        self.user = user
        self.league = league
        self.name = name
        self.bets = bets
        self.parlays = parlays
        self.points = [
            0: 0,
            1: 0,
            2: 0,
            3: 0,
            4: 0,
            5: 0,
            6: 0,
            7: 0,
            8: 0,
            9: 0,
            10: 0,
            11: 0,
            12: 0,
            13: 0,
            14: 0,
            15: 0,
            16: 0
        ]

    }
}
