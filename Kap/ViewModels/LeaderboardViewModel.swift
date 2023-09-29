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

    func generateUserPoints(users: [User], bets: [Bet], parlays: [Parlay], week: Int) async {
        for user in users {
            if let userID = user.id {
                
                func calculateTotalPoints() async -> Double {
                    var totalPoints = 0.0
                    if leagueType == .season {
                        for currentWeek in 1...week {
                            let points = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: currentWeek)
                            let missingBets = await UserViewModel().fetchMissedBetsCount(for: userID, week: currentWeek) ?? 0
                            
                            let pointsWithMissingBets = points + Double(missingBets) * -10.0
                            totalPoints += pointsWithMissingBets
                        }
                    } else {
                        let points = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: week)
                        let missingBets = await UserViewModel().fetchAllMissedBets(for: userID, startingWeek: week)
                        totalPoints = points + Double(missingBets) * -10.0
                    }
                    return totalPoints
                }
                
                let totalPoints = await calculateTotalPoints()
                
                DispatchQueue.main.async {
                    self.usersPoints[userID] = [week: totalPoints]
                }
            }
        }
        DispatchQueue.main.async {
            self.rankedUsers = users.sorted { user1, user2 in
                let points1 = self.usersPoints[user1.id ?? ""]?[week] ?? 0.0
                let points2 = self.usersPoints[user2.id ?? ""]?[week] ?? 0.0
                return points1 > points2
            }
        }
    }

    func getWeeklyPoints(userID: String, bets: [Bet], parlays: [Parlay], week: Int) async -> Double {
        let filteredBets = bets.filter({ $0.playerID == userID && $0.week == week && $0.result != .pending && $0.result != .push })
        let filteredParlays = parlays.filter({ $0.playerID == userID && $0.week == week && $0.result != .pending })
        let points = filteredBets.map { $0.points ?? 0 }.reduce(0, +) + (filteredParlays.first?.totalPoints ?? 0)
        return points
    }
}

func getLeaderboardData(leagueID: String, users: [User], bets: [Bet], parlays: [Parlay]) async -> [User] {
    var rankedUsers = [User]()
    
    for user in users {
        let filteredBets = bets.filter({ $0.playerID == user.id ?? "" && $0.result != .pending})
        let filteredParlays = parlays.filter({ $0.playerID == user.id ?? "" && $0.result != .pending})
        let points = filteredBets.map { $0.points ?? 0 }.reduce(0, +) + (filteredParlays.first?.totalPoints ?? 0)
        // Assuming User has a property to store totalPoints, if not, you need to modify User model
        var newUser = user
        newUser.totalPoints = points
        rankedUsers.append(newUser)
    }
    
    rankedUsers = rankedUsers.sorted { $0.totalPoints ?? 0 > $1.totalPoints ?? 0 }
    return rankedUsers
}




















//func getLeaderboardData(leagueID: String, users: [User], bets: [Bet], parlays: [Parlay]) async -> [User] {
//    var rankedUsers = [User]()
//    
//    for user in users {
//        let newUser = user
//        let bets = bets.filter({ $0.playerID == user.id ?? "" && $0.result != .pending})
//        let parlay = parlays.filter({ $0.playerID == user.id ?? "" && $0.result != .pending})
//        _ = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlay.first?.totalPoints ?? 0)
//        rankedUsers.append(newUser)
//    }
//    
//    rankedUsers = rankedUsers.sorted { $0.totalPoints ?? 0 > $1.totalPoints ?? 0 }
//    
//    return rankedUsers
//}
//
//func getWeeklyPoints(userID: String, bets: [Bet], parlays: [Parlay], week: Int, leagueID: String) async -> Double {
//    let bets = bets.filter({ $0.playerID == userID && $0.week == week && $0.result != .pending && $0.result != .push})
//    let parlays = parlays.filter({ $0.playerID == userID && $0.week == week && $0.result != .pending})
//    let points = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlays.first?.totalPoints ?? 0)
//    
//    return points
//}
//
//func getTotalPoints(userID: String, bets: [Bet], parlays: [Parlay], leagueID: String) async -> Double {
//    let bets = bets.filter({ $0.playerID == userID && $0.result != .pending && $0.result != .push})
//    let parlays = parlays.filter({ $0.playerID == userID && $0.result != .pending})
//    let points = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlays.first?.totalPoints ?? 0)
//    return points
//}
//
//func getWeeklyPointsDifference(userID: String, bets: [Bet], parlays: [Parlay], currentWeek: Int, leagueID: String) async -> Double {
//    let currentWeekPoints = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: currentWeek, leagueID: leagueID)
//    let previousWeekPoints = await getWeeklyPoints(userID: userID, bets: bets, parlays: parlays, week: currentWeek - 1, leagueID: leagueID)
//    return currentWeekPoints - previousWeekPoints
//}
//
//func generateLeaderboards(leagueID: String, users: [User], bets: [Bet], parlays: [Parlay], weeks: [Int]) async -> [[User]] {
//    var boards = [[User]]()
//    
//    for _ in weeks {
//        let board = await getLeaderboardData(leagueID: leagueID, users: users, bets: bets, parlays: parlays)
//        boards.append(board)
//    }
//    return boards
//}
//
//func rank(of user: User, in rankings: [User]) -> Int {
//    return rankings.firstIndex { $0.id ?? "" == user.id ?? ""} ?? -1
//}
//
//func bigMover(from week1: [User], to week2: [User]) -> [(User, up: Bool)] {
//    var bigMovers: [(User, up: Bool)] = []
//    
//    for user in week1 {
//        let week1Rank = rank(of: user, in: week1)
//        let week2Rank = rank(of: user, in: week2)
//
//        let rankDifference = week1Rank - week2Rank
//        
//        if abs(rankDifference) >= 2 {
//            bigMovers.append((user, up: rankDifference > 0))
//        }
//    }
//    
//    return bigMovers
//}
//
//func rankDifference(for user: User, from week1: [User], to week2: [User]) -> Int {
//    let week1Rank = rank(of: user, in: week1)
//    let week2Rank = rank(of: user, in: week2)
//    
//    return week1Rank - week2Rank
//}
