//
//  LeaderboardViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/28/23.
//

import Foundation

class LeaderboardViewModel {
    func getLeaderboardData(leagueID: String, users: [User], bets: [Bet], parlays: [Parlay]) async -> [User] {
        var rankedUsers = [User]()
        
        for user in users {
            var newUser = user
            let bets = bets.filter({ $0.playerID == user.id ?? "" && $0.result != .pending})
            let parlay = parlays.filter({ $0.playerID == user.id ?? "" && $0.result != .pending})
            let points = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlay.first?.totalPoints ?? 0)
//            let missedSundayPoints: Double = Double(7 - bets.filter({ $0.betOption.game.dayType == DayType.sunday.rawValue}).count) * -10.0
//            let missedMondayPoints: Double = Double(1 - bets.filter({ $0.betOption.game.dayType == DayType.mnf.rawValue}).count) * -10.0
//            let missedSNFPoints: Double = Double(1 - bets.filter({ $0.betOption.game.dayType == DayType.snf.rawValue}).count) * -10.0
//            let missedTNFPoints: Double = Double(1 - bets.filter({ $0.betOption.game.dayType == DayType.tnf.rawValue}).count) * -10.0
            
            newUser.totalPoints = points
            rankedUsers.append(newUser)
        }
        
        rankedUsers = rankedUsers.sorted { $0.totalPoints ?? 0 > $1.totalPoints ?? 0 }
        
        return rankedUsers
    }
    
    func getWeeklyPoints(userID: String, bets: [Bet], parlays: [Parlay], week: Int, leagueID: String) async -> Double {
        let bets = bets.filter({ $0.playerID == userID && $0.week == week && $0.result != .pending})
        let parlays = parlays.filter({ $0.playerID == userID && $0.week == week && $0.result != .pending})
        let points = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlays.first?.totalPoints ?? 0)
        
        return points
    }
    
    func getTotalPoints(userID: String, bets: [Bet], parlays: [Parlay], leagueID: String) async -> Double {
        let bets = bets.filter({ $0.playerID == userID && $0.result != .pending})
        let parlays = parlays.filter({ $0.playerID == userID && $0.result != .pending})
        let points = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlays.first?.totalPoints ?? 0)
        
//        let missedSundayPoints: Double = Double(7 - bets.filter({ $0.betOption.game.dayType == DayType.sunday.rawValue}).count) * -10.0
//        let missedMondayPoints: Double = Double(1 - bets.filter({ $0.betOption.game.dayType == DayType.mnf.rawValue}).count) * -10.0
//        let missedSNFPoints: Double = Double(1 - bets.filter({ $0.betOption.game.dayType == DayType.snf.rawValue}).count) * -10.0
//        let missedTNFPoints: Double = Double(1 - bets.filter({ $0.betOption.game.dayType == DayType.tnf.rawValue}).count) * -10.0
        
        return points
    }
    
    func getWeeklyPointsDifference(userID: String, bets: [Bet], parlays: [Parlay], currentWeek: Int, leagueID: String) async -> Double {
        let currentWeekPoints = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: currentWeek, leagueID: leagueID)
        let previousWeekPoints = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: currentWeek - 1, leagueID: leagueID)
        return currentWeekPoints - previousWeekPoints
    }
    
    func generateLeaderboards(leagueID: String, users: [User], bets: [Bet], parlays: [Parlay], weeks: [Int]) async -> [[User]] {
        var boards = [[User]]()
        
        for week in weeks {
            let board = await getLeaderboardData(leagueID: leagueID, users: users, bets: bets, parlays: parlays)
            boards.append(board)
        }
        
        return boards
    }
    
    func rank(of user: User, in rankings: [User]) -> Int {
        return rankings.firstIndex { $0.id ?? "" == user.id ?? ""} ?? -1
    }

    func bigMover(from week1: [User], to week2: [User]) -> [(User, up: Bool)] {
        var bigMovers: [(User, up: Bool)] = []
        
        for user in week1 {
            let week1Rank = rank(of: user, in: week1)
            let week2Rank = rank(of: user, in: week2)

            let rankDifference = week1Rank - week2Rank
            
            if abs(rankDifference) >= 2 {
                bigMovers.append((user, up: rankDifference > 0))
            }
        }
        
        return bigMovers
    }
    
    func rankDifference(for user: User, from week1: [User], to week2: [User]) -> Int {
        let week1Rank = rank(of: user, in: week1)
        let week2Rank = rank(of: user, in: week2)
        
        return week1Rank - week2Rank
    }
//    let movers = bigMover(from: week1Ranked, to: week2Ranked)
//    for (player, up) in movers {
//        print("\(player.name) is a big mover and they moved \(up ? "up" : "down")!")
//    }
}
