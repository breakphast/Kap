//
//  LeaderboardViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/28/23.
//

import Foundation

class LeaderboardViewModel {
    func getLeaderboardData(leagueID: String, users: [User], bets: [Bet], week: Int) async -> [User] {
        var rankedUsers = [User]()
        
        for user in users {
            var newUser = user
            let bets = bets.filter({ $0.playerID == user.id ?? "" && $0.week == week && $0.result != .pending})
            let points = bets.map { $0.points ?? 0 }.reduce(0, +)
            newUser.totalPoints = points
            rankedUsers.append(newUser)
        }
        
        rankedUsers = rankedUsers.sorted { $0.totalPoints ?? 0 > $1.totalPoints ?? 0 }
        
        return rankedUsers
    }
    
    func getWeeklyPoints(user: User, bets: [Bet], week: Int, leagueID: String) async -> Int {
        let bets = bets.filter({ $0.playerID == user.id ?? "" && $0.week == week && $0.result != .pending})
        let points = bets.map { $0.points ?? 0 }.reduce(0, +)
        
        return points
    }
    
    func generateLeaderboards(leagueID: String, users: [User], bets: [Bet], weeks: [Int]) async -> [[User]] {
        var boards = [[User]]()
        
        for week in weeks {
            let board = await getLeaderboardData(leagueID: leagueID, users: users, bets: bets, week: week)
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
            
            if abs(rankDifference) > 1 {
                bigMovers.append((user, up: rankDifference > 0))
            }
        }
        
        return bigMovers
    }
    
    
//    let movers = bigMover(from: week1Ranked, to: week2Ranked)
//    for (player, up) in movers {
//        print("\(player.name) is a big mover and they moved \(up ? "up" : "down")!")
//    }
}
