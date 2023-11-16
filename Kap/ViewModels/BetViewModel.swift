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
    
    func recreateBet(bet: BetModel, games: [GameModel], playerID: String, in context: NSManagedObjectContext) {
        let newBetData: [String: Any] = [
            "isDeleted": true,
            "deletedTimestamp": Date(),
            "id": bet.id + "deleted",
            "betOption": bet.betOption,
            "game": bet.game.documentID ?? "",
            "type": bet.type,
            "result": bet.result,
            "odds": bet.odds,
            "points": bet.points,
            "stake": 100,
            "betString": bet.betString,
            "selectedTeam": bet.selectedTeam ?? "",
            "playerID": playerID,
            "week": bet.week,
            "leagueID": bet.leagueCode,
            "timestamp": Timestamp(date: Date())
        ]

        let newBetID = bet.id + "deleted"
        let newBet = self.db.collection("allBets2").document(newBetID)
        newBet.setData(newBetData) { err in
            if let err = err {
                print("Error creating new bet document: \(err)")
            } else {
                print("Document successfully created with new ID")
            }
        }
        print("Added new deleted bet to the cloud.")
    }
    
    func fetchUpdatedBets(games: [GameModel], leagueCode: String) async throws -> [Bet] {
        let querySnapshot = try await db.collection("allBets2").whereField("result", isNotEqualTo: BetResult.pending.rawValue).getDocuments()
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
        return bets.filter({$0.isDeleted == false})
    }
    
    func fetchStampedBets(games: [GameModel], leagueCode: String, timeStamp: Date?) async throws -> [Bet] {
        if let timeStamp {
            let querySnapshot = try await db.collection("allBets2").whereField("timestamp", isGreaterThan: Timestamp(date: timeStamp)).getDocuments()
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
            return bets.filter({$0.isDeleted == false})
        } else {
            let querySnapshot = try await db.collection("allBets2").whereField("leagueID", isEqualTo: leagueCode).getDocuments()
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
            return bets.filter({$0.isDeleted == false})
        }
    }
    
    func fetchDeletedStampedBets(games: [GameModel], leagueCode: String, deletedTimestamp: Date?) async throws -> [Bet] {
        if let deletedTimestamp {
            let querySnapshot = try await db.collection("allBets2").whereField("deletedTimestamp", isGreaterThan: Timestamp(date: deletedTimestamp )).getDocuments()
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
            return bets.filter({$0.isDeleted == true})
        } else {
            return []
        }
    }

    
    func fetchBets(games: [GameModel], week: Int? = nil, leagueCode: String) async throws -> [Bet] {
        let db = Firestore.firestore()
            let querySnapshot: QuerySnapshot?

            if week == nil {
                querySnapshot = try await db.collection("allBets2").whereField("leagueID", isEqualTo: leagueCode).getDocuments()
            } else if let weekValue = week {
                querySnapshot = try await db.collection("allBets2")
                    .whereField("leagueID", isEqualTo: leagueCode)
                    .whereField("week", isEqualTo: weekValue)
                    .getDocuments()
            } else {
                throw NSError(domain: "InvalidArguments", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Either provide both games and week or just games"])
            }

            guard let documents = querySnapshot?.documents else {
                return []
            }
        
        let bets = documents.map { queryDocumentSnapshot -> Bet in
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
            let betString = data["betString"] as? String
            let foundGame = self.findBetGame(games: games, gameID: game)
            let leagueID = data["leagueID"] as? String ?? ""
            let timestamp = data["timestamp"] as? Timestamp
            let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
            let isDeleted = data["isDeleted"] as? Bool ?? false
            let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
            let date = GameService().dateFromISOString(date2 ?? "")
            let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
            let date4 = GameService().dateFromISOString(date3 ?? "")
            
            let bet = Bet(id: id, betOption: betOption, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueID, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
            bet.betString = betString ?? ""
            return bet
        }
        return bets.filter({$0.isDeleted == false})
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
        betModel.timestamp = bet.timestamp
        
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
        
        let _ = try await db.collection("allBets2").document(bet.id).setData(newBet)
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
    
    func updateBet(bet: BetModel) {
        let newbet = db.collection("allBets2").document(bet.id)
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
        let newbet = db.collection("allBets2").document(bet.id)
        
        newbet.updateData([
            "isDeleted": true,
            "deletedTimestamp": Date(),
            "id": bet.id + "deleted"
        ]) { err in
            if let err = err {
                print("Error updating BETTTT: \(err)", bet.id)
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateBetForDeletion(bet: BetModel) -> BetModel {
        let newBet = bet
        newBet.id = bet.id + "deleted"
        
        return newBet
    }
    
    func updateDeletedParlay(parlay: ParlayModel) {
        let newParlay = db.collection("allParlays").document(parlay.id ?? "")
        
        newParlay.updateData([
            "isDeleted": true,
            "deletedTimestamp": Date()
        ]) { err in
            if let err = err {
                print("Error updating BETTTT: \(err)", parlay.id ?? "")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateBetAttribute(bet: Bet, attribute: String, value: Any) {
        let newbet = db.collection("allBets2").document(bet.id)
        newbet.updateData([
            attribute: value,
        ]) { err in
            if let err = err {
                print("Error updating BETTTT: \(err)", bet.id)
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func updateCloudBetResults(bets: [BetModel]) async throws {
        print("Starting result updates...")
        for bet in bets {
            if bet.result == "Pending" {
                let newbet = db.collection("allBets2").document(bet.id)

                bet.result = bet.game.betResult(for: bet).rawValue
                bet.points = bet.result == BetResult.push.rawValue ? 0 : bet.result == BetResult.loss.rawValue ? -10 : bet.points

                do {
                    try await updateDataAsync(document: newbet, data: [
                        "result": bet.result,
                        "points": bet.result == BetResult.push.rawValue ? 0 : bet.result == BetResult.loss.rawValue ? -10 : bet.points
                    ])
                    print("Bet result successfully updated")
                } catch {
                    print("Error updating BET RESULT: \(error)")
                }
            } else {
                continue
            }
        }
    }
    
    func checkForNewBets(in context: NSManagedObjectContext, leagueCode: String, bets: [BetModel], parlays: [ParlayModel], timestamp: Date?, counter: Counter?, games: [GameModel], userID: String) async throws {
        var stampedBets = try await BetViewModel().fetchStampedBets(games: games, leagueCode: leagueCode, timeStamp: timestamp != nil ? timestamp : nil)
        
        let localBetIDs = Set(bets).map {$0.id}
        stampedBets = stampedBets.filter { !localBetIDs.contains($0.id) }
        
        if !stampedBets.isEmpty {
            print("New bets detected:", stampedBets.count)
            BetViewModel().convertToBetModels(bets: stampedBets, counter: counter, in: context)
        }
        
        let deletedStampedBets = try await BetViewModel().fetchDeletedStampedBets(games: games, leagueCode: leagueCode, deletedTimestamp: timestamp)
        if !deletedStampedBets.isEmpty {
            for bet in deletedStampedBets {
                guard bets.contains(where: { $0.id + "deleted" == bet.id }) && bet.playerID != userID else { return }
                BetViewModel().deleteBetModel(in: context, id: String(bet.id.dropLast(7)))
                if let _ = counter?.timestamp {
                    var timestamp = Date()
                    
                    if let lastTimestamp = leagueBets.last?.timestamp {
                        timestamp = lastTimestamp
                    }
                    if let lastTimestamp = parlays.last?.timestamp {
                        if lastTimestamp > timestamp {
                            timestamp = lastTimestamp
                        }
                    }
                    counter?.timestamp = timestamp
                    print("New timestamp after removing bet.", timestamp)
                }
            }
        }
    }
    
    func updateLocalBetResults(games: [GameModel], week: Int, bets: [BetModel], leagueCode: String, in context: NSManagedObjectContext) async throws {
        let updatedBets = try await fetchBets(games: games, week: week, leagueCode: leagueCode).filter({ $0.result != .pending })
        print("Starting local result updates...")
        for bet in bets.filter({$0.result == BetResult.pending.rawValue}) {
            if let newBet = updatedBets.first(where: {$0.id == bet.id}) {
                bet.result = newBet.result?.rawValue ?? ""
                bet.points = newBet.result?.rawValue == BetResult.push.rawValue ? 0 : newBet.result?.rawValue == BetResult.loss.rawValue ? -10 : bet.points
            }
        }
        do {
            try context.save() 
            print("\(updatedBets.filter({$0.result != .pending}).count) Bet results successfully updated locally")
        } catch {
            
        }
    }
    
    func updateLocalBets(games: [GameModel], week: Int, bets: [BetModel], leagueCode: String, in context: NSManagedObjectContext) async throws {
        do {
            try await BetViewModel().updateLocalBetResults(games: games, week: week, bets: Array(bets), leagueCode: leagueCode, in: context)
        } catch {
            
        }
    }
    
    func addInitialBets(games: [GameModel], leagueCode: String, in context: NSManagedObjectContext) async throws {
        do {
            let fetchedBets = try await BetViewModel().fetchBets(games: games, leagueCode: leagueCode)
            print(fetchedBets.map({$0.timestamp}))
            if fetchedBets.isEmpty {
                print("No league bets have been placed yet.")
            } else {
                for bet in fetchedBets {
                    BetViewModel().addBetToLocalDatabase(bet: bet, playerID: bet.playerID, in: context)
                }
            }
        } catch {
            
        }
    }
    
    func createBetModel(from bet: Bet, in context: NSManagedObjectContext) -> BetModel {
        let betModel = BetModel(context: context)
        
        // Set the attributes on the GameModel from the Game
        betModel.id = bet.id
        betModel.betOption = bet.betOption
        betModel.game = bet.game
        betModel.type = bet.type.rawValue
        betModel.result = bet.result?.rawValue ?? "Pending"
        betModel.odds = Int16(bet.odds)
        betModel.selectedTeam = bet.selectedTeam
        betModel.playerID = bet.playerID
        betModel.week = Int16(bet.week)
        betModel.leagueCode = bet.leagueCode
        betModel.stake = 100.0
        betModel.betString = bet.betString
        betModel.points = bet.points ?? 0
        betModel.betOptionString = bet.betOptionString
        betModel.timestamp = bet.timestamp
        
        return betModel
    }
    
    func convertToBetModels(bets: [Bet], counter: Counter?, in context: NSManagedObjectContext) {
        for bet in bets.sorted(by: {$0.game.date ?? Date() < $1.game.date ?? Date()}) {
            let betModel = createBetModel(from: bet, in: context)
            
            if bets.last?.id == bet.id {
                if let timestamp = betModel.timestamp {
                    if let counter {
                        counter.timestamp = timestamp
                        print("New timestamp from last bet added: ", bet.timestamp ?? "") 
                    }
                }
            }
        }
        do {
            try context.save()
            print("Saved new bets locally.")
        } catch {
            print("Error saving context: \(error)")
        }
    }

    // This is the function that wraps the callback-based Firestore method to make it awaitable
    func updateDataAsync(document: DocumentReference, data: [String: Any]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            document.updateData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func deleteBet(betID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("allBets2").document(betID).delete() { error in
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
