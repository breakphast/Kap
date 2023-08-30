//
//  HomeViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI
import Observation
import SwiftData
import Firebase
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var leagues: [League] = []
    @Published var games: [Game] = []
    @Published var bets: [Bet] = []
    @Published var generatedBets: [Bet] = []
    @Published var parlays: [Parlay] = []
    @Published var selectedBets: [Bet] = []
    @Published var activeParlays: [Parlay] = []
    @Published var players: [Player] = []
    @Published var leaderboards: [[User]] = [[]]
    
    @Published var activePlayer: Player?
    @Published var activeUserID: String
    @Published var currentWeek = 1
    @Published var activeLeague: League?
    
    @Published var changed: Bool = false
    
    init(activeUserID: String) {
        self.activeUserID = activeUserID
    }
    
    enum FetchError: Error {
        case noDocumentsFound
    }
    
    enum Week: Int {
        case week1 = 1
        case week2
        case week3
        case week4
        case week5
        case week6
        
        static func from(dayDifference: Int) -> Week {
            let currentWeekNumber = (dayDifference / 7) + 1
            return Week(rawValue: currentWeekNumber) ?? .week1
        }
    }
    
    func setCurrentWeek() {
        let calendar = Calendar.current
        
        // Finding the most recent Sunday
        var components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
        let daysSinceSunday = (components.weekday! - calendar.firstWeekday + 7) % 7
        guard let lastSunday = calendar.date(byAdding: .day, value: -daysSinceSunday, to: Date()) else {
            return
        }
        
        guard let diffDays = calendar.dateComponents([.day], from: lastSunday, to: Date()).day else {
            return
        }
        
        currentWeek = Week.from(dayDifference: diffDays).rawValue
    }
}
