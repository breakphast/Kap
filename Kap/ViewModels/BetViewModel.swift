//
//  BetViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore
import Firebase
import CoreData
import SwiftUI

class BetViewModel: ObservableObject {
    @Published var fireBets = [Bet]()
    @Published var allBets = [Bet]()
    @Published var leagueBets = [Bet]()
    
    let db = Firestore.firestore()
    
    func fetchStampedBets(games: [GameModel], leagueCode: String, timeStamp: Date?) async throws -> [Bet] {
        if let timeStamp {
            let querySnapshot = try await db.collection("userBets").whereField("timestamp", isGreaterThan: Timestamp(date: timeStamp)).getDocuments()
            let bets = querySnapshot.documents.map { queryDocumentSnapshot -> Bet in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let game = data["game"] as? String ?? ""
                let betOption = data["betOption"] as? String ?? ""
                let type = data["type"] as? String ?? ""
                let odds = data["odds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let selectedTeam = data["selectedTeam"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let foundGame = self.findBetGame(games: games, gameID: game)
                let leagueID = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                let bet = Bet(id: id, betOption: betOption, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueID, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                
                return bet
            }
            return bets
        } else {
            let querySnapshot = try await db.collection("userBets").whereField("leagueID", isEqualTo: leagueCode).getDocuments()
            let bets = querySnapshot.documents.map { queryDocumentSnapshot -> Bet in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let game = data["game"] as? String ?? ""
                let betOption = data["betOption"] as? String ?? ""
                let type = data["type"] as? String ?? ""
                let odds = data["odds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let selectedTeam = data["selectedTeam"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let foundGame = self.findBetGame(games: games, gameID: game)
                let leagueID = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                let bet = Bet(id: id, betOption: betOption, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueID, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                
                return bet
            }
            return bets
        }
    }
    
    func fetchDeletedStampedBets(games: [GameModel], leagueCode: String, deletedTimestamp: Date?) async throws -> [Bet] {
        if let deletedTimestamp {
            let querySnapshot = try await db.collection("userBets").whereField("deletedTimestamp", isGreaterThan: Timestamp(date: deletedTimestamp )).getDocuments()
            let bets = querySnapshot.documents.map { queryDocumentSnapshot -> Bet in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let game = data["game"] as? String ?? ""
                let betOption = data["betOption"] as? String ?? ""
                let type = data["type"] as? String ?? ""
                let odds = data["odds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let selectedTeam = data["selectedTeam"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let foundGame = self.findBetGame(games: games, gameID: game)
                let leagueID = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                let bet = Bet(id: id, betOption: betOption, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueID, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                
                return bet
            }
            return bets
        } else {
            return []
        }
    }

    
    func fetchBets(games: [GameModel], leagueCode: String) async throws -> [Bet] {
        
        let querySnapshot = try await db.collection("userBets").whereField("leagueID", isEqualTo: leagueCode).getDocuments()
        let bets = querySnapshot.documents.map { queryDocumentSnapshot -> Bet in
            let data = queryDocumentSnapshot.data()
            
            let id = data["id"] as? String ?? ""
            let game = data["game"] as? String ?? ""
            let betOption = data["betOption"] as? String ?? ""
            let type = data["type"] as? String ?? ""
            let odds = data["odds"] as? Int ?? 0
            let result = data["result"] as? String ?? ""
            let selectedTeam = data["selectedTeam"] as? String ?? ""
            let playerID = data["playerID"] as? String ?? ""
            let week = data["week"] as? Int ?? 0
            let foundGame = self.findBetGame(games: games, gameID: game)
            let leagueID = data["leagueID"] as? String ?? ""
            let timestamp = data["timestamp"] as? Date
            let deletedTimestamp = data["deletedTimestamp"] as? Date
            let isDeleted = data["isDeleted"] as? Bool ?? false
            
            let bet = Bet(id: id, betOption: betOption, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueID, timestamp: timestamp, deletedTimestamp: deletedTimestamp, isDeleted: isDeleted)
            
            return bet
        }
        return bets
    }


    func findBetGame(games: [GameModel], gameID: String) -> GameModel? {
        if let game = games.first(where: { $0.documentID == gameID }) {
            return game
        } else {
            print("No game found with ID: \(gameID)")
            return nil
        }
    }
    
    func stringToBetType(_ typeString: String) -> BetType? {
        return BetType(rawValue: typeString)
    }
    
    func stringToBetResult(_ resultString: String) -> BetResult? {
        return BetResult(rawValue: resultString)
    }
    
    func addBetToLocalDatabase(bet: Bet, playerID: String, in context: NSManagedObjectContext) {
        let betModel = BetModel(context: context)
        betModel.id = bet.id
        betModel.betOption = bet.betOption
        betModel.game = bet.game
        betModel.type = bet.type.rawValue
        betModel.result = bet.result?.rawValue ?? ""
        betModel.odds = Int16(bet.odds)
        betModel.points = bet.points ?? 0
        betModel.stake = 100
        betModel.betString = bet.betString
        betModel.selectedTeam = bet.selectedTeam ?? ""
        betModel.playerID = playerID
        betModel.week = Int16(bet.week)
        betModel.leagueCode = bet.leagueCode
        betModel.timestamp = Date()
        
        do {
            try context.save()
            print("Added bet locally:", betModel.id)
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func addBet(bet: Bet, playerID: String, in context: NSManagedObjectContext) async throws {
        let db = Firestore.firestore()
        
        let newBet: [String: Any] = [
            "id": bet.id,
            "betOption": bet.betOption,
            "game": bet.game.documentID ?? "",
            "type": bet.type.rawValue,
            "result": bet.result?.rawValue ?? "",
            "odds": bet.odds,
            "points": bet.points ?? 0,
            "stake": 100,
            "betString": bet.betString,
            "selectedTeam": bet.selectedTeam ?? "",
            "playerID": playerID,
            "week": bet.week,
            "leagueID": bet.leagueCode,
            "timestamp": Timestamp(date: Date())
        ]
        
        let _ = try await db.collection("userBets").document(bet.id).setData(newBet)
        print("Added bet to the cloud.")
        addBetToLocalDatabase(bet: bet, playerID: bet.playerID, in: context)
    }
    
    func makeBet(for game: GameModel, betOption: String, playerID: String, week: Int, leagueCode: String) -> Bet? {
        guard let betOptionsSet = game.betOptions,
              let betOptionsArray = betOptionsSet.allObjects as? [BetOptionModel] else {
            print("Error: Unable to process bet options.")
            return nil
        }
        
        if let option = betOptionsArray.first(where: { $0.id == betOption }) {
            let bet = Bet(id: betOption + playerID + leagueCode,
                          betOption: betOption,
                          game: game,
                          type: BetType(rawValue: option.betType ?? "") ?? .moneyline,
                          result: .pending,
                          odds: Int(option.odds),
                          selectedTeam: option.selectedTeam,
                          playerID: playerID,
                          week: week,
                          leagueCode: leagueCode,
                          timestamp: Date(),
                          deletedTimestamp: nil,
                          isDeleted: false
            )
            return bet
        } else {
            print("Error: Bet option not found.")
            return nil
        }
    }
    
    func updateBet(bet: Bet) {
        let newbet = db.collection("userBets").document(bet.id)
        newbet.updateData([
            "betString": bet.betString,
            "result": bet.game.betResult(for: bet).rawValue
        ]) { err in
            if let err = err {
                print("Error updating BETTTT: \(err)", bet.id)
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateDeletedBet(bet: BetModel) {
        let newbet = db.collection("userBets").document(bet.id)
        
        newbet.updateData([
            "isDeleted": true,
            "deletedTimestamp": Date()
        ]) { err in
            if let err = err {
                print("Error updating BETTTT: \(err)", bet.id)
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateBetLeague(bet: Bet, leagueCode: String) {
        let newbet = db.collection("userBets").document(bet.id)
        newbet.updateData([
            "leagueID": leagueCode,
        ]) { err in
            if let err = err {
                print("Error updating BETTTT: \(err)", bet.id)
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateParlay(parlay: Parlay) {
        let newParlay = db.collection("parlays").document(parlay.id)
        let parlayBets = parlay.bets
        if !parlayBets.filter({ $0.game.betResult(for: $0) == .loss }).isEmpty {
            newParlay.updateData([
                "result": BetResult.loss.rawValue
            ]) { err in
                if let err = err {
                    print("Error updating LAYYY: \(err)")
                } else {
                    print("Document successfully updated. L")
                }
            }
        } else if parlayBets.filter({$0.result == .win}).count == parlayBets.count {
            newParlay.updateData([
                "result": BetResult.win.rawValue
            ]) { err in
                if let err = err {
                    print("Error updating LAYYYYY: \(err)")
                } else {
                    print("Document successfully updated. DUB.")
                }
            }
        }
        
        if parlay.result == .loss {
            newParlay.updateData([
                "totalPoints":  -10
            ]) { err in
                if let err = err {
                    print("Error updating LAYYYY: \(err)")
                } else {
                    print("Document successfully updated. L POINTS")
                }
            }
        }
    }
    
    func updateBetResult(bet: Bet, result: BetResult) {
        guard bet.result == .pending else { return }
        
        let newbet = db.collection("userBets").document(bet.id)
        if let newPoints = bet.points {
            newbet.updateData([
                "result": result.rawValue,
                "points": result == .push ? 0 : result == .loss ? -10 : newPoints
            ]) { err in
                if let err = err {
                    print("Error updating BET RESULT: \(err)")
                } else {
                    print("Bet result successfully updated")
                    
                }
            }
        }
    }
    
    func deleteBet(betID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("userBets").document(betID).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                    print("Deleted bet in cloud: \(betID)")
                }
            }
        }
    }
    
    func deleteBetModel(in context: NSManagedObjectContext, id: String) {
        let fetchRequest: NSFetchRequest<BetModel> = BetModel.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entityToDelete = entities.first(where: {$0.id == id}) {
                context.delete(entityToDelete)
                
                try context.save()
                print("Deleted bet in local:", id)
            } else {
                // Entity with the specified attribute value not found
            }
        } catch {
            // Handle error
        }
    }
    
    func generateBetsForGame(_ game: GameModel) -> [Bet] {
        var bets = [Bet]()
        guard let betOptionsArray = game.betOptions?.allObjects as? [BetOptionModel] else {
            return []
        }
        
        for option in betOptionsArray {
            let bet = Bet(id: option.id ?? "", betOption: option.id ?? "", game: game, type: BetType(rawValue: option.betType!) ?? .moneyline, result: .pending, odds: Int(option.odds), selectedTeam: option.id?.last == "1" ? game.homeTeam : game.awayTeam, playerID: "", week: 0, leagueCode: "", timestamp: nil, deletedTimestamp: nil, isDeleted: false)
            bets.append(bet)
        }

        bets.sort { a, b in
            let orderA = sortOrder(for: a.id)
            let orderB = sortOrder(for: b.id)
            return orderA < orderB
        }
        return bets
    }
    
    func sortOrder(for id: String) -> Int {
        let order = ["spread2", "ml2", "over", "spread1", "ml1", "under"]
        
        for (index, element) in order.enumerated() {
            if id.hasSuffix(element) {
                return index
            }
        }
        
        return order.count
    }
}
