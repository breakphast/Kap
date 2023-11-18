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
    @Published var allParlays: [ParlayModel] = []
    @Published var selectedBets: [Bet] = []
    @Published var activeParlay: Parlay?
    @Published var players: [Player] = []
    @Published var leaderboards: [[User]] = [[]]
    
    @Published var activePlayer: Player?
    @Published var currentWeek = 11
    @Published var activeLeague: League?
    @Published var currentDate: String = ""
    
    @Published var changed: Bool = false
    @Published var showingSplashScreen = true
    
    @Published var activeleagueCode: String?
    @Published var leagueCodes: [String] = ["2222", "5555", "3214"]
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
    
    func pedestrianRefresh(in context: NSManagedObjectContext, games: [GameModel], bets: [BetModel], parlays: [ParlayModel], leagueCode: String, userID: String) async throws {
        if let newWeek = try await fetchCurrentWeek(), newWeek > currentWeek {
            DispatchQueue.main.async {
                self.currentWeek = newWeek
            }
        }
        try await GameService().updateLocalGameOdds(games: Array(games).filter({$0.week == currentWeek}), week: currentWeek, in: context)
        fetchEntities(GameModel.self, in: context) { result in
            switch result {
            case .success(let games):
                self.allGames = games
            case .failure(let error):
                print("Error \(error)")
            }
        }
        try await BetViewModel().updateLocalBetResults(games: Array(games), bets: Array(bets), leagueCode: leagueCode, in: context)
        fetchEntities(BetModel.self, in: context) { result in
            switch result {
            case .success(let bets):
                self.allBets = bets
            case .failure(let error):
                print("Error \(error)")
            }
        }
        
        try await BetViewModel().checkForNewBets(in: context, leagueCode: leagueCode, bets: Array(bets), parlays: Array(parlays), timestamp: counter?.timestamp, counter: counter, games: Array(allGames), userID: userID)
    }
    
        func personalRefresh(in context: NSManagedObjectContext, games: [GameModel], bets: [BetModel], parlays: [ParlayModel], leagueCode: String) async throws {
//            try await GameService().updateCloudGameOdds(week: currentWeek)
//            try await GameService().updateLocalGameOdds(games: games, week: currentWeek, in: context)
            fetchEntities(GameModel.self, in: context) { result in
                switch result {
                case .success(let games):
                    self.allGames = games
                case .failure(let error):
                    print("Error \(error)")
                }
            }           
            // cloud scores
            try await GameService().updateCloudGameScores(games: games)
            fetchEntities(GameModel.self, in: context) { result in
                switch result {
                case .success(let games):
                    self.allGames = games
                case .failure(let error):
                    print("Error \(error)")
                }
            }            
            try await GameService().updateLocalGameScores(in: context, week: currentWeek)
            fetchEntities(GameModel.self, in: context) { result in
                switch result {
                case .success(let games):
                    self.allGames = games
                case .failure(let error):
                    print("Error \(error)")
                }
            }            
            // cloud bets and parlays results
            try await BetViewModel().updateCloudBetResults(bets: leagueBets)
            fetchEntities(BetModel.self, in: context) { result in
                switch result {
                case .success(let bets):
                    self.allBets = bets
                case .failure(let error):
                    print("Error \(error)")
                }
            }            
            try await BetViewModel().updateLocalBetResults(games: Array(games), bets: Array(bets), leagueCode: leagueCode, in: context)
            fetchEntities(BetModel.self, in: context) { result in
                switch result {
                case .success(let bets):
                    self.allBets = bets
                case .failure(let error):
                    print("Error \(error)")
                }
            }    
            try await ParlayViewModel().updateCloudParlayResults(parlays: Array(leagueParlays))
            try await ParlayViewModel().updateLocalParlayResults(games: Array(games), parlays: Array(parlays), leagueCode: leagueCode, in: context)
            //        homeViewModel.allParlayModels = allParlayModels
        }
    
    func fetchEntities<T: NSManagedObject>(_ entity: T.Type, in context: NSManagedObjectContext, completion: @escaping (Result<[T], Error>) -> Void) {
        let fetchRequest = T.fetchRequest()
        DispatchQueue.main.async {
            do {
                if let results = try context.fetch(fetchRequest) as? [T] {
                    completion(.success(results))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not cast fetch results to the expected type."])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
//    func fetchEssentials(updateGames: Bool, updateScores: Bool, league: League, in context: NSManagedObjectContext) async {
//        do {
//            guard let leaguePlayers = league.players else {
//                throw NSError(domain: "HomeViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error: league players are nil."])
//            }
//
//            let fetchedUsers = try await UserViewModel().fetchAllUsers(leagueUsers: leaguePlayers)
//            let relevantUsers = fetchedUsers.filter { leaguePlayers.contains($0.id ?? "") }
//
//            fetchEntities(GameModel.self, in: context, completion: { result in
//                switch result {
//                case .success(let games):
//                    self.allGames = games
//                    self.weekGames = games.filter { $0.week == self.currentWeek }
//                case .failure(let error):
//                    print("Error \(error)")
//                }
//            })
//        } catch {
//            print("Failed with error: \(error.localizedDescription)")
//        }
//    }
}
