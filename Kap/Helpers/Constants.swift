//
//  Constants.swift
//  Kap
//
//  Created by Desmond Fitch on 7/28/23.
//

import Foundation

let nflTeams = [
    "Miami Dolphins": "MIA Dolphins",
    "New England Patriots": "NE Patriots",
    "Buffalo Bills": "BUF Bills",
    "New York Jets": "NYJ Jets",
    "Pittsburgh Steelers": "PIT Steelers",
    "Baltimore Ravens": "BAL Ravens",
    "Cleveland Browns": "CLE Browns",
    "Cincinnati Bengals": "CIN Bengals",
    "Tennessee Titans": "TEN Titans",
    "Indianapolis Colts": "IND Colts",
    "Houston Texans": "HOU Texans",
    "Jacksonville Jaguars": "JAX Jaguars",
    "Kansas City Chiefs": "KC Chiefs",
    "Las Vegas Raiders": "LV Raiders",
    "Denver Broncos": "DEN Broncos",
    "Los Angeles Chargers": "LAC Chargers",
    "Dallas Cowboys": "DAL Cowboys",
    "Philadelphia Eagles": "PHI Eagles",
    "New York Giants": "NYG Giants",
    "Washington Commanders": "WAS Commanders",
    "Green Bay Packers": "GB Packers",
    "Chicago Bears": "CHI Bears",
    "Minnesota Vikings": "MIN Vikings",
    "Detroit Lions": "DET Lions",
    "San Francisco 49ers": "SF 49ers",
    "Seattle Seahawks": "SEA Seahawks",
    "Los Angeles Rams": "LA Rams",
    "Arizona Cardinals": "ARI Cardinals",
    "Atlanta Falcons": "ATL Falcons",
    "New Orleans Saints": "NO Saints",
    "Tampa Bay Buccaneers": "TB Buccaneers",
    "Carolina Panthers": "CAR Panthers"
]

let nflLogos = [
    "Miami Dolphins": "dolphins",
    "New England Patriots": "patriots",
    "Buffalo Bills": "bills",
    "New York Jets": "jets",
    "Pittsburgh Steelers": "steelers",
    "Baltimore Ravens": "ravens",
    "Cleveland Browns": "browns",
    "Cincinnati Bengals": "bengals",
    "Tennessee Titans": "titans",
    "Indianapolis Colts": "colts",
    "Houston Texans": "texans",
    "Jacksonville Jaguars": "jaguars",
    "Kansas City Chiefs": "chiefs",
    "Las Vegas Raiders": "raiders",
    "Denver Broncos": "broncos",
    "Los Angeles Chargers": "chargers",
    "Dallas Cowboys": "cowboys",
    "Philadelphia Eagles": "eagles",
    "New York Giants": "giants",
    "Washington Commanders": "commanders",
    "Green Bay Packers": "packers",
    "Chicago Bears": "bears",
    "Minnesota Vikings": "vikings",
    "Detroit Lions": "lions",
    "San Francisco 49ers": "49ers",
    "Seattle Seahawks": "seahawks",
    "Los Angeles Rams": "rams",
    "Arizona Cardinals": "cardinals",
    "Atlanta Falcons": "falcons",
    "New Orleans Saints": "saints",
    "Tampa Bay Buccaneers": "bucs",
    "Carolina Panthers": "panthers"
]

let mlbLogos = [
    "Baltimore Orioles": "orioles",
    "Boston Red Sox": "redsox",
    "New York Yankees": "yankees",
    "Tampa Bay Rays": "rays",
    "Toronto Blue Jays": "bluejays",
    "Chicago White Sox": "whitesox",
    "Cleveland Guardians": "guardians",
    "Detroit Tigers": "tigers",
    "Kansas City Royals": "royals",
    "Minnesota Twins": "twins",
    "Houston Astros": "astros",
    "Los Angeles Angels": "angels",
    "Oakland Athletics": "athletics",
    "Seattle Mariners": "mariners",
    "Texas Rangers": "rangers",
    "Atlanta Braves": "braves",
    "Miami Marlins": "marlins",
    "New York Mets": "mets",
    "Philadelphia Phillies": "phillies",
    "Washington Nationals": "nationals",
    "Chicago Cubs": "cubs",
    "Cincinnati Reds": "reds",
    "Milwaukee Brewers": "brewers",
    "Pittsburgh Pirates": "pirates",
    "St. Louis Cardinals": "cardinals",
    "Arizona Diamondbacks": "diamondbacks",
    "Colorado Rockies": "rockies",
    "Los Angeles Dodgers": "dodgers",
    "San Diego Padres": "padres",
    "San Francisco Giants": "giants"
]

let mlbTeams = [
    "Baltimore Orioles": "BAL Orioles",
    "Boston Red Sox": "BOS Red Sox",
    "New York Yankees": "NYY Yankees",
    "Tampa Bay Rays": "TB Rays",
    "Toronto Blue Jays": "TOR Blue Jays",
    "Chicago White Sox": "CWS White Sox",
    "Cleveland Guardians": "CLE Guardians",
    "Detroit Tigers": "DET Tigers",
    "Kansas City Royals": "KC Royals",
    "Minnesota Twins": "MIN Twins",
    "Houston Astros": "HOU Astros",
    "Los Angeles Angels": "LAA Angels",
    "Oakland Athletics": "OAK Athletics",
    "Seattle Mariners": "SEA Mariners",
    "Texas Rangers": "TEX Rangers",
    "Atlanta Braves": "ATL Braves",
    "Miami Marlins": "MIA Marlins",
    "New York Mets": "NYM Mets",
    "Philadelphia Phillies": "PHI Phillies",
    "Washington Nationals": "WSH Nationals",
    "Chicago Cubs": "CHC Cubs",
    "Cincinnati Reds": "CIN Reds",
    "Milwaukee Brewers": "MIL Brewers",
    "Pittsburgh Pirates": "PIT Pirates",
    "St. Louis Cardinals": "STL Cardinals",
    "Arizona Diamondbacks": "ARI Diamondbacks",
    "Colorado Rockies": "COL Rockies",
    "Los Angeles Dodgers": "LAD Dodgers",
    "San Diego Padres": "SD Padres",
    "San Francisco Giants": "SF Giants"
]

import CoreData

class DataManager {
    let managedObjectContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
    }
    
    func convertToGameModel(games: [Game], in context: NSManagedObjectContext) -> [GameModel] {
        var gameModels: [GameModel] = []
        
        for game in games {
            let gameModel = GameModel(context: context)
            
            gameModel.id = game.id
            gameModel.homeTeam = game.homeTeam
            gameModel.awayTeam = game.awayTeam
            gameModel.date = game.date
            gameModel.homeSpread = game.homeSpread
            gameModel.awaySpread = game.awaySpread
            gameModel.homeMoneyLine = Int16(game.homeMoneyLine)
            gameModel.awayMoneyLine = Int16(game.awayMoneyLine)
            gameModel.over = game.over
            gameModel.under = game.under
            gameModel.completed = game.completed
            gameModel.homeScore = game.homeScore
            gameModel.awayScore = game.awayScore
            gameModel.homeSpreadPriceTemp = game.homeSpreadPriceTemp
            gameModel.awaySpreadPriceTemp = game.awaySpreadPriceTemp
            gameModel.overPriceTemp = game.overPriceTemp
            gameModel.underPriceTemp = game.underPriceTemp
            gameModel.week = Int16(game.week ?? 0)
            gameModel.documentID = game.documentId
            
            for betOption in game.betOptions {
                let betOptionModel = BetOptionModel(context: context)
                betOptionModel.id = betOption.id
                betOptionModel.odds = Int16(betOption.odds)
                betOptionModel.spread = betOption.spread ?? 0
                betOptionModel.over = betOption.over
                betOptionModel.under = betOption.under
                betOptionModel.betType = betOption.betType.rawValue
                betOptionModel.selectedTeam = betOption.selectedTeam
                betOptionModel.betString = betOption.betString
            }
            
            gameModels.append(gameModel)
        }
        return gameModels
    }
}
