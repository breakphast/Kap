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

class AppDataViewModel: ObservableObject {
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
}
