//
//  swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import CoreData

class HomeViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var leagues: [League] = []
    @Published var weekGames: [GameModel] = []
    @Published var allGames: [GameModel] = []
    @Published var allBets: [BetModel] = []
    @Published var generatedBets: [Bet] = []
    @Published var allParlays: [Parlay] = []
    @Published var selectedBets: [Bet] = []
    @Published var activeParlay: Parlay?
    @Published var players: [Player] = []
    @Published var leaderboards: [[User]] = [[]]
    
    @Published var activePlayer: Player?
    @Published var currentWeek = 9
    @Published var activeLeague: League?
    @Published var currentDate: String = ""
    
    @Published var changed: Bool = false
    @Published var showingSplashScreen = true
    
    @Published var activeleagueCode: String?
    @Published var leagueCodes: [String] = ["2222", "5555"]
    @Published var userLeagues: [League] = []
    @Published var leagueType: LeagueType = .weekly
    
    @Published var leagueBets = [BetModel]()
    @Published var userBets = [BetModel]()
    @Published var leagueParlays = [ParlayModel]()
    @Published var userParlays = [ParlayModel]()
    
    @Published var allGameModels: FetchedResults<GameModel>?
    @Published var allBetModels: FetchedResults<BetModel>?
    @Published var allParlayModels: FetchedResults<ParlayModel>?
    @Published var counter: Counter?
        
    let db = Firestore.firestore()
    
    let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter
    }()
    
    init() {
        DispatchQueue.main.async {
            Task {
                self.currentWeek = try await self.fetchCurrentWeek() ?? 7
                print("Week: ", self.currentWeek)
                try await self.leagues = LeagueViewModel().fetchAllLeagues()
            }
        }
    }
    
    enum FetchError: Error {
        case noDocumentsFound
    }
    
    func updateLocalTimestamp(in context: NSManagedObjectContext, timestamp: Date?) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Counter")
        fetchRequest.predicate = NSPredicate(format: "attributeName == %@", "attributeValue")
        
        let counter = Counter(context: context)
        if let timestamp {
            counter.timestamp = timestamp
            print("Local timestamp:", timestamp)
        } else {
            counter.timestamp = nil
        }
        
        do {
            try context.save()
            self.counter = counter
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func originalFetch(updateScores: Bool, updateGames: Bool, updateLeaderboards: Bool) async {
        do {
            let activeDate = self.formatter.string(from: Date())
            
            DispatchQueue.main.async {
                self.currentDate = activeDate
            }
        }
    }
    
    func setCurrentWeek() {
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: Date())
        let daysSinceSunday = (components.weekday! - calendar.firstWeekday + 7) % 7
        guard let lastSunday = calendar.date(byAdding: .day, value: -daysSinceSunday, to: Date()) else {
            return
        }
        
        guard let diffDays = calendar.dateComponents([.day], from: lastSunday, to: Date()).day else {
            return
        }
        
        currentWeek = Utility.Week.from(dayDifference: diffDays).rawValue
    }
    
    func fetchCurrentWeek() async throws -> Int? {
        let db = Firestore.firestore()
        let docRef = db.collection("currentWeek").document("currentWeek")
        
        let document = try await docRef.getDocument()
        if document.exists {
            return document.data()?["week"] as? Int
        }
        return nil
    }
    
    func pedestrianRefresh(in context: NSManagedObjectContext, games: [GameModel], bets: [BetModel], parlays: [ParlayModel], leagueCode: String) async throws {
        if let newWeek = try await fetchCurrentWeek(), newWeek > currentWeek {
            currentWeek = newWeek
        }
        try await Board().updateLocalGameOdds(games: Array(games).filter({$0.week == currentWeek}), week: currentWeek, in: context)
//        self.allGameModels = allGameModels
        
        try await BetViewModel().updateLocalBetResults(games: Array(games), week: currentWeek, bets: Array(bets), leagueCode: leagueCode, in: context)
//        self.allBetModels = allBetModels
        
        try await BetViewModel().checkForNewBets(in: context, leagueCode: leagueCode, bets: Array(bets), parlays: Array(parlays), timestamp: counter?.timestamp, counter: counter, games: Array(allGames))
    }
}
