//
//  LeaderboardViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/28/23.
//

import Foundation

class LeaderboardViewModel: ObservableObject {
    @Published var rankedUsers: [User] = []
    @Published var usersPoints: [String: [Int: Double]] = [:]
    @Published var leagueType: LeagueType = .season

    func generateUserPoints(users: [User], bets: [BetModel], parlays: [ParlayModel], games: [GameModel], currentWeek: Int, week: Int, leagueCode: String) async {
        let userBets = Dictionary(grouping: bets, by: { $0.playerID })
        await withTaskGroup(of: Void.self) { group in
            for user in users {
                group.addTask {
                    if let userID = user.id {
                        var points: Double = 0
                        let missedBets = self.calculateMissingBets(user: user, games: games, bets: bets, currentWeek: currentWeek)
                        for currentWeek in 11...week {
                            let newPoints = await self.getWeeklyPoints(userID: userID, bets: userBets[userID] ?? [], parlays: parlays, week: currentWeek)
                            points += newPoints
                            points -= Double(missedBets) * 10
                        }
                        DispatchQueue.main.async {
                            self.usersPoints[userID] = [week: points]
                        }
                    }
                }
            }
            await group.waitForAll()
        }
        
        DispatchQueue.main.async {
            self.rankedUsers = users.sorted { user1, user2 in
                let points1 = self.usersPoints[user1.id ?? ""]?[week] ?? 0.0
                let points2 = self.usersPoints[user2.id ?? ""]?[week] ?? 0.0
                return points1 > points2
            }
        }
    }
    
    func calculateMissingBets(user: User, games: [GameModel], bets: [BetModel], week: Int? = nil, currentWeek: Int) -> Int {
        let userId = user.id ?? ""

        if let week = week {
            if games.contains(where: { $0.week == week && !$0.completed }) {
                return 0
            } else {
                return 10 - bets.filter({ $0.week == week && $0.playerID == userId }).count
            }
        } else {
            let weeksCompleted = (currentWeek - 1) - 10
            let totalBets = weeksCompleted * 10
            let actualBets = bets.filter({ $0.playerID == userId && $0.game.week != currentWeek}).count
            return totalBets - actualBets
        }
    }
    
    func generateWeeklyUserPoints(users: [User], bets: [BetModel], parlays: [ParlayModel], games: [GameModel], week: Int, leagueCode: String, currentWeek: Int) async {
        await withTaskGroup(of: Void.self) { group in
            for user in users {
                group.addTask {
                    if let userID = user.id {
                        let points = await self.getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: week)
                        DispatchQueue.main.async {
                            let missedBets = self.calculateMissingBets(user: user, games: games, bets: bets, week: week, currentWeek: currentWeek)
                            self.usersPoints[userID] = [week: (points - (Double(missedBets) * 10))]
                        }
                    }
                }
            }
            await group.waitForAll()
        }
        
        DispatchQueue.main.async {
            self.rankedUsers = users.sorted { user1, user2 in
                let points1 = self.usersPoints[user1.id ?? ""]?[week] ?? 0.0
                let points2 = self.usersPoints[user2.id ?? ""]?[week] ?? 0.0
                return points1 > points2
            }
        }
    }

    func getWeeklyPoints(userID: String, bets: [BetModel], parlays: [ParlayModel], week: Int) async -> Double {
        // Filtering bets
        let filteredBets = bets.filter {
            $0.week == week && $0.result != "Pending" && $0.playerID == userID
        }
        
        // Calculating points from bets
        var betPoints = 0.0
        for bet in filteredBets {
            betPoints += bet.points 
        }
        
        // Filtering parlays
        var filteredParlays = parlays.filter {
            $0.playerID == userID && $0.week == week
        }
        filteredParlays = filteredParlays.filter({$0.result != "Pending"})
        
        // Getting points from parlays
        let parlayPoints = filteredParlays.first?.totalPoints ?? 0
        
        // Summing up points from bets and parlays
        let totalPoints = betPoints + Double(parlayPoints)
        
        return totalPoints
    }

    
    func calculateTotalPointsPlayersView(userID: String, bets: [BetModel], parlays: [ParlayModel], week: Int, leagueCode: String) async -> Double {
        var totalPoints = 0.0
        for currentWeek in 1...week {
            let points = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: currentWeek)
            totalPoints += points
        }
        return totalPoints
    }
}
