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
    var games: [Game] = []
    var bets: [Bet] = []
    var parlays: [Parlay] = []
    var selectedBets: [Bet] = []
    var activeParlays: [Parlay] = []
    var players: [Player] = []
    
    var activePlayer: Player?
    var activeUser: User?
    var currentWeek = 2
    var activeLeague: League?
    
    var changed: Bool = false
    
    init() {
        self.users = [
            User(email: "desmond@gmail.com", name: "ThePhast", leagues: []),
            User(email: "desmond@gmail.com", name: "RingoMingo", leagues: []),
            User(email: "desmond@gmail.com", name: "Harch", leagues: []),
            User(email: "desmond@gmail.com", name: "Brokeee", leagues: []),
            User(email: "desmond@gmail.com", name: "Mingy", leagues: [])
        ]
    }
    
    enum FetchError: Error {
        case noDocumentsFound
    }
    
    func generateRandomNumberInRange(range: ClosedRange<Int>) -> Int {
        return Int.random(in: range)
    }
}
