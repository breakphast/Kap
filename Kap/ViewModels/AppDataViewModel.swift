//
//  AppDataViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI
import Observation
import SwiftData
import Firebase
import FirebaseFirestore

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
    var selectedBets: [Bet] = []
    var activeParlays: [Parlay] = []
    var currentPlayer: Player?
    
    init() {
        self.users = [
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "ThePhast", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "RingoMingo", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Harch", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Brokeee", leagues: []),
            User(userID: UUID(), email: "desmond@gmail.com", password: "123456", name: "Mingy", leagues: [])
        ]
        
        let db = Firestore.firestore()
        let ref = db.collection("users")
        ref.getDocuments { snapshot, error in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            if let snapshot = snapshot {
                for document in snapshot.documents {
                    let data = document.data()
                    
                    let email = data["email"] as? String ?? ""
                    let password = data["password"] as? String ?? ""
                    let name = data["name"] as? String ?? ""
                    let leagues = data["leagues"] as? [League] ?? []
                    
                    let user = User(userID: UUID(), email: email, password: password, name: name, leagues: leagues)
                }
            }
        }
    }
    
    func addUser(user: User) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(user.userID.uuidString)
        ref.setData(["email": user.email, "password": user.password, "name": user.name, "leagues": user.leagues]) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    func addLeague(league: League) {
        let db = Firestore.firestore()
        let ref = db.collection("leagues").document(league.leagueID.uuidString)
        let newLeague: [String: Any] = [
            "name": leagues[0].name,
            "dateCreated": Timestamp(date: Date()),
            "currentSeason": 2023,
            "players": []
        ]
        
        ref.setData(newLeague)
    }
    
    func addGames(games: [Game]) {
        let db = Firestore.firestore()
        let ref = db.collection("nflGames")
        for game in games {
            ref.addDocument(data: game.dictionary) { error in
                if let error = error {
                    print("Error adding game: \(error.localizedDescription)")
                } else {
                    print("Game successfully added!")
                }
            }
        }
    }
    
    func addPlayerToLeague(leagueID: String, user: User, playerName: String) async throws {
        let db = Firestore.firestore()

        let newPlayer: [String: Any] = [
            "id": user.userID.uuidString,
            "user": [
                "userID": user.userID.uuidString,
                "email": user.email,
                "name": user.name
            ],
            "league": leagueID,
            "name": playerName,
            "bets": [],
            "parlays": [],
            "points": Dictionary(uniqueKeysWithValues: (0...16).map { ("\($0)", 0) })
        ]
        
        let _ = try await db.collection("players").addDocument(data: newPlayer)
        let leagueRef = db.collection("leagues").document("wfFEbLN9GpiR1LPYJc4H")
        try await leagueRef.updateData([
            "players": FieldValue.arrayUnion([newPlayer["id"]!])
        ])
    }
    
    func addBet(bet: Bet, player: Player) async throws {
        let db = Firestore.firestore()

        let newBet: [String: Any] = [
            "id": UUID().uuidString,
            "betOption": bet.betOption.id.uuidString,
            "game": bet.game.id,
            "type": bet.type.rawValue,
            "result": bet.result?.rawValue ?? "",
            "odds": bet.odds,
            "points": bet.points ?? 0,
            "stake": 100,
            "betString": bet.betString,
            "selectedTeam": bet.selectedTeam ?? ""
        ]
        
        let _ = try await db.collection("bets").addDocument(data: newBet)
    }
    
    private let db = Firestore.firestore()
    
    func fetchData() async throws -> [Bet] {
        let querySnapshot = try await db.collection("bets").getDocuments() // getDocuments is asynchronous
        let bets = querySnapshot.documents.map { queryDocumentSnapshot -> Bet in
            let data = queryDocumentSnapshot.data()
            
            let id = data["id"] as? String ?? ""
            let game = data["game"] as? String ?? ""
            let betOption = data["betOption"] as? String ?? ""
            let type = data["type"] as? String ?? ""
            let odds = data["odds"] as? Int ?? 0
            let result = data["result"] as? String ?? ""
            let selectedTeam = data["selectedTeam"] as? String ?? ""
            let (foundGame, foundBetOption) = self.findBetOption(gameID: game, betOptionID: betOption)
            
            let bet = Bet(id: UUID(uuidString: id)!, betOption: foundBetOption!, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam)
            
            return bet
        }
        self.bets = bets
        return bets
    }

    enum FetchError: Error {
        case noDocumentsFound
    }


    
    func fetchGamesFromFirestore() async throws -> [Game] {
        let db = Firestore.firestore()
        let querySnapshot = try await db.collection("nflGames").getDocuments()

        return querySnapshot.documents.map { queryDocumentSnapshot -> Game in
                let data = queryDocumentSnapshot.data()
            
            let id = data["id"] as? String ?? ""
            let homeTeam = data["homeTeam"] as? String ?? ""
            let awayTeam = data["awayTeam"] as? String ?? ""
            let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
            let homeSpread = data["homeSpread"] as? Double ?? 0.0
            let awaySpread = data["awaySpread"] as? Double ?? 0.0
            let homeMoneyLine = data["homeMoneyLine"] as? Int ?? 0
            let awayMoneyLine = data["awayMoneyLine"] as? Int ?? 0
            let over = data["over"] as? Double ?? 0.0
            let under = data["under"] as? Double ?? 0.0
            let completed = data["completed"] as? Bool ?? false
            let homeScore = data["homeScore"] as? String
            let awayScore = data["awayScore"] as? String
            let homeSpreadPriceTemp = data["homeSpreadPriceTemp"] as? Double ?? 0.0
            let awaySpreadPriceTemp = data["awaySpreadPriceTemp"] as? Double ?? 0.0
            let overPriceTemp = data["overPriceTemp"] as? Double ?? 0.0
            let underPriceTemp = data["underPriceTemp"] as? Double ?? 0.0

            let gameElement = GameElement(id: id, sportKey: .football_nfl, sportTitle: .NFL, commenceTime: date, completed: completed, homeTeam: homeTeam, awayTeam: awayTeam, bookmakers: nil, scores: [Score(name: homeTeam, score: homeScore ?? ""), Score(name: awayTeam, score: awayScore ?? "")])

            let game = Game(gameElement: gameElement)
            game.homeSpread = homeSpread
            game.awaySpread = awaySpread
            game.homeMoneyLine = homeMoneyLine
            game.awayMoneyLine = awayMoneyLine
            game.over = over
            game.under = under
            game.homeSpreadPriceTemp = homeSpreadPriceTemp
            game.awaySpreadPriceTemp = awaySpreadPriceTemp
            game.overPriceTemp = overPriceTemp
            game.underPriceTemp = underPriceTemp
            game.completed = completed
            
            if let betOptionsDictionaries = data["betOptions"] as? [[String: Any]] {
                game.betOptions = betOptionsDictionaries.compactMap {
                    BetOption.fromDictionary($0, game: game)
                }
            }

            return game
        }
    }

    func fetchGames() async {
        do {
            self.games = try await fetchGamesFromFirestore()
            updateDayType(for: &games)
        } catch {
            print("Failed to fetch games: \(error.localizedDescription)")
        }
    }

    
    func findBetOption(gameID: String, betOptionID: String) -> (Game?, BetOption?) {
        guard let game = games.first(where: { $0.id == gameID }) else {
            print("No game")
            return (nil, nil) }
        
        guard let betOption = game.betOptions.first(where: { $0.id.uuidString == betOptionID }) else { return (game, nil) }
        
        return (game, betOption)
    }
    
    // A function to convert a string to its BetType enum case
    func stringToBetType(_ typeString: String) -> BetType? {
        return BetType(rawValue: typeString)
    }
    
    // A function to convert a string to its BetResult enum case
    func stringToBetResult(_ resultString: String) -> BetResult? {
        return BetResult(rawValue: resultString)
    }

    
    func getLeaderboardData() async -> [Player] {
        do {
            let league = AppDataViewModel().createLeague(name: "BIG JOHN SILVER", players: [])
            let season = AppDataViewModel().createSeason(league: league, year: 2023)
            let week = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 0)
            let week2 = await AppDataViewModel().createWeek(season: season, league: season.league, weekNumber: 1)
            // MARK: - VM.weeks and VM.games is what we're using right now and VM.players
            
            league.seasons[0].weeks.append(week)
            league.seasons[0].weeks.append(week2)
            weeks.append(week)
            weeks.append(week2)
            
            leagues.append(league)
                        
//            games = try await GameService().getGames()
//            
//            weeks[0].games = games
//            updateDayType(for: &weeks[0].games)
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
        league.seasons.append(createSeason(league: league, year: league.currentSeason))
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
        return week
    }
}
