//  ParlayViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI
import CoreData

class ParlayViewModel {
    private let db = Firestore.firestore()
    
    func fetchParlays(games: [GameModel], week: Int? = nil, leagueCode: String) async throws -> [Parlay] {
        let querySnapshot: QuerySnapshot?

        if week == nil {
            querySnapshot = try await db.collection("allParlays").whereField("leagueID", isEqualTo: leagueCode).getDocuments()
        } else if let weekValue = week {
            querySnapshot = try await db.collection("allParlays")
                .whereField("leagueID", isEqualTo: leagueCode)
                .whereField("week", isEqualTo: weekValue)
                .getDocuments()
        } else {
            throw NSError(domain: "InvalidArguments", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Either provide both games and week or just games"])
        }

        guard let documents = querySnapshot?.documents else {
            return []
        }
                
        let parlays = documents.compactMap { queryDocumentSnapshot -> Parlay? in
            let data = queryDocumentSnapshot.data()
            
            let id = data["id"] as? String ?? ""
            let betsData = data["bets"] as? [[String: Any]] ?? []
            let totalOdds = data["totalOdds"] as? Int ?? 0
            let resultString = data["result"] as? String ?? ""
            let result = BetResult(rawValue: resultString) // if BetResult conforms to RawRepresentable with a default case, otherwise provide a default value
            let betString = data["betString"] as? String ?? ""
            let playerID = data["playerID"] as? String ?? ""
            let week = data["week"] as? Int ?? 0
            let leagueCode = data["leagueID"] as? String ?? ""
            let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
            let deletedTimestamp = data["deletedTimestamp"] as? Timestamp ?? Timestamp(date: Date())
            let isDeleted = data["isDeleted"] as? Bool ?? false
            
            var bets = [Bet]()
            for betData in betsData {
                let gameID = betData["game"] as? String ?? ""
                let betOptionID = betData["betOption"] as? String ?? ""
                let typeString = betData["type"] as? String ?? ""
                let type = BetType(rawValue: typeString) // if BetType conforms to RawRepresentable with a default case, otherwise provide a default value
                let odds = betData["odds"] as? Int ?? 0
                let selectedTeam = betData["selectedTeam"] as? String ?? ""
                let playerID = betData["playerID"] as? String ?? ""
                let week = betData["week"] as? Int ?? 0
                let leagueCode = betData["leagueID"] as? String ?? ""
                let timestamp = betData["timestamp"] as? Date ?? Date()
                let result = data["result"] as? String ?? ""
                
                let foundGame = BetViewModel().findBetGame(games: games, gameID: gameID)
                if let foundGame = foundGame {
                    let bet = Bet(id: betOptionID + playerID + id + "parlayLeg", betOption: betOptionID, game: foundGame, type: type!, result: BetViewModel().stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: timestamp, deletedTimestamp: nil, isDeleted: nil)
                    bets.append(bet)
                }
            }
            
            let date2 = GameService().convertTimestampToISOString(timestamp: timestamp)
            let date = GameService().dateFromISOString(date2 ?? "")
            let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp)
            let date4 = GameService().dateFromISOString(date3 ?? "")
            let parlay = Parlay(id: id, bets: bets, totalOdds: totalOdds, result: BetResult(rawValue: (result?.rawValue)!) ?? .pending, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
            parlay.totalOdds = totalOdds
            parlay.betString = betString
            
            return parlay
        }

        return parlays.filter({$0.isDeleted == false || $0.isDeleted == nil})
    }
    
    func addParlayToLocalDatabase(parlay: Parlay, playerID: String, in context: NSManagedObjectContext) {
        let parlayModel = ParlayModel(context: context)
        parlayModel.id = parlay.id
        parlayModel.totalOdds = Int16(parlay.totalOdds)
        parlayModel.result = parlay.result.rawValue
        parlayModel.totalPoints = parlay.totalPoints
        parlayModel.betString = parlay.betString
        parlayModel.playerID = parlay.playerID
        parlayModel.week = Int16(parlay.week)
        parlayModel.leagueCode = parlay.leagueCode
        parlayModel.timestamp = parlay.timestamp
        
        for bet in parlay.bets {
            let betModel = BetModel(context: context)
            betModel.id = bet.betOption + bet.playerID + parlay.id + "parlayLeg"
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
            
            parlayModel.addToBets(betModel)
        }
        
        do {
            try context.save()
            print("Added parlay locally:", parlayModel.id ?? "")
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func doThisForParlays(parlays: [Parlay], in context: NSManagedObjectContext) async {
        
    }
    
    func addParlay(parlay: Parlay, in context: NSManagedObjectContext) async throws {
        var newParlay: [String: Any] = [
            "id": parlay.id,
            "bets": parlay.bets.map { bet in
                [
                    "id": bet.betOption + bet.playerID + parlay.id + "parlayLeg",
                    "betOption": bet.betOption,
                    "game": bet.game.documentID ?? "",
                    "type": bet.type.rawValue,
                    "odds": bet.odds,
                    "result": bet.result?.rawValue ?? "",
                    "selectedTeam": bet.selectedTeam ?? "",
                    "week": parlay.week,
                    "playerID": parlay.playerID,
                    "leagueID": parlay.leagueCode,
                    "timestamp": Timestamp(date: Date())
                ] as [String : Any]
            },
            "result": parlay.result.rawValue,
            "totalOdds": parlay.totalOdds,
            "totalPoints": parlay.totalPoints,
            "playerID": parlay.playerID,
            "week": parlay.week,
            "leagueID": parlay.leagueCode,
            "timestamp": Timestamp(date: Date())
        ]
        
        var betString: String {
            var strings: [String] = []
            
            for bet in parlay.bets {
                if bet.type == .spread {
                    strings.append("\(bet.selectedTeam ?? "") \(bet.betString)")
                } else {
                    strings.append(bet.betString)
                }
            }
            return strings.joined(separator: ", ")
        }
        
        newParlay["betString"] = betString
        parlay.betString = betString
        parlay.timestamp = Date()

        let _ = try await db.collection("allParlays").document(parlay.id).setData(newParlay)
        print("Added parlay to cloud", parlay.id)
        addParlayToLocalDatabase(parlay: parlay, playerID: parlay.playerID, in: context)
    }
    
    func checkForNewParlays(in context: NSManagedObjectContext, leagueCode: String, parlays: [ParlayModel], games: [GameModel], counter: Counter?, timestamp: Date?, userID: String) async throws {
        var stampedParlays = try await ParlayViewModel().fetchStampedParlays(games: games, leagueCode: leagueCode, timeStamp: timestamp != nil ? timestamp : nil)
        let localParlayIDs = Set(parlays).map {$0.id}
        stampedParlays = stampedParlays.filter { !localParlayIDs.contains($0.id) }
        
        if !stampedParlays.isEmpty {
            print("New parlays detected:", stampedParlays.count)
            convertToParlayModels(parlays: stampedParlays, counter: counter, in: context)
        }
        
        var deletedStampedParlays = try await ParlayViewModel().fetchDeletedStampedParlays(games: games, leagueCode: leagueCode, deletedTimeStamp: timestamp)
        let allParlayModelIDs = parlays.compactMap { $0.id + "deleted" }
        let idSet = Set(allParlayModelIDs)
        deletedStampedParlays = deletedStampedParlays.filter { idSet.contains($0.id) && $0.playerID != userID}
        
        if !deletedStampedParlays.isEmpty {
            for parlay in deletedStampedParlays {
                if let timestamp = parlay.timestamp {
                    ParlayViewModel().deleteParlayModel(in: context, id: String(parlay.id.dropLast(7)), timestamp: timestamp)
                }
            }
        }
    }
    
    func addInitialParlays(games: [GameModel], leagueCode: String, in context: NSManagedObjectContext) async throws {
        do {
            let fetchedParlays = try await ParlayViewModel().fetchParlays(games: games, leagueCode: leagueCode)
            if fetchedParlays.isEmpty {
                print("No league parlays have been placed yet.")
            } else {
                for parlay in fetchedParlays {
                    ParlayViewModel().addParlayToLocalDatabase(parlay: parlay, playerID: parlay.playerID, in: context)
                }
            }
        } catch {
            
        }
    }
    
    func convertToParlayModels(parlays: [Parlay], counter: Counter?, in context: NSManagedObjectContext) {
        for parlay in parlays {
            let parlayModel = ParlayModel(context: context)
            
            parlayModel.id = parlay.id
            parlayModel.totalOdds = Int16(parlay.totalOdds)
            parlayModel.result = parlay.result.rawValue
            parlayModel.totalPoints = parlay.totalPoints
            parlayModel.betString = parlay.betString
            parlayModel.playerID = parlay.playerID
            parlayModel.week = Int16(parlay.week)
            parlayModel.leagueCode = parlay.leagueCode
            parlayModel.timestamp = parlay.timestamp
            
            for bet in parlay.bets {
                let betModel = BetViewModel().createBetModel(from: bet, in: context)
                parlayModel.addToBets(betModel)
            }
            
            if parlays.last?.id == parlay.id {
                if let timestamp = parlayModel.timestamp {
                    if let localTimestamp = counter?.timestamp {
                        if timestamp > localTimestamp {
                            counter?.timestamp = timestamp
                            if let stamp = parlay.timestamp {
                                print("New timestamp from last parlay added: ", stamp)
                            }
                        }
                    }
                }
            }
        }
        do {
            try context.save()
            print("Saved new parlays locally.")
        } catch {
            print("Error saving context: \(error)")
        }
    }
    
    func fetchStampedParlays(games: [GameModel], leagueCode: String, timeStamp: Date?) async throws -> [Parlay] {
        if let timeStamp {
            let querySnapshot = try await db.collection("allParlays").whereField("timestamp", isGreaterThan: Timestamp(date: timeStamp)).getDocuments()
            let parlays = querySnapshot.documents.map { queryDocumentSnapshot -> Parlay in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let betsData = data["bets"] as? [[String: Any]] ?? [[:]]
                let totalOdds = data["totalOdds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let betString = data["betString"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let leagueCode = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                var bets = [Bet]()
                for betData in betsData {
                    guard
                        let id = betData["id"] as? String,
                        let gameID = betData["game"] as? String,
                        let betOptionID = betData["betOption"] as? String,
                        let typeString = betData["type"] as? String,
                        let type = BetType(rawValue: typeString),
                        let odds = betData["odds"] as? Int,
                        let selectedTeam = betData["selectedTeam"] as? String,
                        let playerID = betData["playerID"] as? String,
                        let week = betData["week"] as? Int,
                        let leagueCode = data["leagueID"] as? String,
                        let timestamp = data["timestamp"] as? Timestamp
                    else {
                        print("Invalid parlay bet.")
                        continue
                    }
                    let foundGame = BetViewModel().findBetGame(games: games, gameID: gameID)
                    if let foundGame = foundGame {
                        let date2 = GameService().convertTimestampToISOString(timestamp: timestamp)
                        let date = GameService().dateFromISOString(date2 ?? "")
                        
                        let bet = Bet(id: id, betOption: betOptionID, game: foundGame, type: type, result: BetViewModel().stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: nil, isDeleted: nil)
                        bets.append(bet)
                    }
                }
                
                let parlay = Parlay(id: id, bets: bets, totalOdds: totalOdds, result: BetViewModel().stringToBetResult(result)!, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                parlay.totalOdds = totalOdds
                parlay.betString = betString
                parlay.bets = bets
                return parlay
            }
            return parlays.filter({$0.isDeleted == false && $0.leagueCode == leagueCode})
        } else {
            let querySnapshot = try await db.collection("allParlays").getDocuments()
            let parlays = querySnapshot.documents.map { queryDocumentSnapshot -> Parlay in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let betsData = data["bets"] as? [[String: Any]] ?? [[:]]
                let totalOdds = data["totalOdds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let betString = data["betString"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let leagueCode = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                var bets = [Bet]()
                for betData in betsData {
                    guard
                        let id = betData["id"] as? String,
                        let gameID = betData["game"] as? String,
                        let betOptionID = betData["betOption"] as? String,
                        let typeString = betData["type"] as? String,
                        let type = BetType(rawValue: typeString),
                        let odds = betData["odds"] as? Int,
                        let selectedTeam = betData["selectedTeam"] as? String,
                        let playerID = betData["playerID"] as? String,
                        let week = betData["week"] as? Int,
                        let leagueCode = data["leagueID"] as? String
                    else {
                        continue
                    }
                    let foundGame = BetViewModel().findBetGame(games: games, gameID: gameID)
                    if let foundGame = foundGame {
                        let bet = Bet(id: id, betOption: betOptionID, game: foundGame, type: type, result: BetViewModel().stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: nil, isDeleted: nil)
                        bets.append(bet)
                    }
                }
                
                let parlay = Parlay(id: id, bets: bets, totalOdds: totalOdds, result: BetViewModel().stringToBetResult(result)!, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                parlay.totalOdds = totalOdds
                parlay.betString = betString
                
                return parlay
            }
            return parlays.filter({$0.isDeleted == false && $0.leagueCode == leagueCode})
        }
    }

    func fetchDeletedStampedParlays(games: [GameModel], leagueCode: String, deletedTimeStamp: Date?) async throws -> [Parlay] {
        if deletedTimeStamp != nil {
            let querySnapshot = try await db.collection("allParlays").whereField("isDeleted", isEqualTo: true).getDocuments()
            let parlays = querySnapshot.documents.map { queryDocumentSnapshot -> Parlay in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let betsData = data["bets"] as? [[String: Any]] ?? [[:]]
                let totalOdds = data["totalOdds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let betString = data["betString"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let leagueCode = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                var bets = [Bet]()
                for betData in betsData {
                    guard
                        let id = betData["id"] as? String,
                        let gameID = betData["game"] as? String,
                        let betOptionID = betData["betOption"] as? String,
                        let typeString = betData["type"] as? String,
                        let type = BetType(rawValue: typeString),
                        let odds = betData["odds"] as? Int,
                        let selectedTeam = betData["selectedTeam"] as? String,
                        let playerID = betData["playerID"] as? String,
                        let week = betData["week"] as? Int,
                        let leagueCode = data["leagueID"] as? String
                    else {
                        continue
                    }
                    let foundGame = BetViewModel().findBetGame(games: games, gameID: gameID)
                    if let foundGame = foundGame {
                        let bet = Bet(id: id, betOption: betOptionID, game: foundGame, type: type, result: BetViewModel().stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: nil, isDeleted: nil)
                        bets.append(bet)
                    }
                }
                
                let parlay = Parlay(id: id, bets: bets, totalOdds: totalOdds, result: BetViewModel().stringToBetResult(result)!, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                parlay.totalOdds = totalOdds
                parlay.betString = betString
                
                return parlay
            }
            return parlays.filter({$0.isDeleted == true})
        } else {
            let querySnapshot = try await db.collection("allParlays").getDocuments()
            let parlays = querySnapshot.documents.map { queryDocumentSnapshot -> Parlay in
                let data = queryDocumentSnapshot.data()
                
                let id = data["id"] as? String ?? ""
                let betsData = data["bets"] as? [[String: Any]] ?? [[:]]
                let totalOdds = data["totalOdds"] as? Int ?? 0
                let result = data["result"] as? String ?? ""
                let betString = data["betString"] as? String ?? ""
                let playerID = data["playerID"] as? String ?? ""
                let week = data["week"] as? Int ?? 0
                let leagueCode = data["leagueID"] as? String ?? ""
                let timestamp = data["timestamp"] as? Timestamp
                let date2 = GameService().convertTimestampToISOString(timestamp: timestamp ?? Timestamp(date: Date()))
                let date = GameService().dateFromISOString(date2 ?? "")
                let deletedTimestamp = data["deletedTimestamp"] as? Timestamp
                let date3 = GameService().convertTimestampToISOString(timestamp: deletedTimestamp ?? Timestamp(date: Date()))
                let date4 = GameService().dateFromISOString(date3 ?? "")
                let isDeleted = data["isDeleted"] as? Bool ?? false
                
                var bets = [Bet]()
                for betData in betsData {
                    guard
                        let id = betData["id"] as? String,
                        let gameID = betData["game"] as? String,
                        let betOptionID = betData["betOption"] as? String,
                        let typeString = betData["type"] as? String,
                        let type = BetType(rawValue: typeString),
                        let odds = betData["odds"] as? Int,
                        let selectedTeam = betData["selectedTeam"] as? String,
                        let playerID = betData["playerID"] as? String,
                        let week = betData["week"] as? Int,
                        let leagueCode = data["leagueID"] as? String,
                        let timestamp = data["timestamp"] as? Date
                    else {
                        continue
                    }
                    let foundGame = BetViewModel().findBetGame(games: games, gameID: gameID)
                    if let foundGame = foundGame {
                        let bet = Bet(id: id, betOption: betOptionID, game: foundGame, type: type, result: BetViewModel().stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: timestamp, deletedTimestamp: nil, isDeleted: nil)
                        bets.append(bet)
                    }
                }
                let parlay = Parlay(id: id, bets: bets, totalOdds: totalOdds, result: BetViewModel().stringToBetResult(result)!, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: date ?? Date(), deletedTimestamp: date4 ?? Date(), isDeleted: isDeleted)
                parlay.totalOdds = totalOdds
                parlay.betString = betString
                
                return parlay
            }
            return parlays.filter({$0.isDeleted == true})
        }
    }
    
    func deleteParlay(parlayID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("allParlays").document(parlayID).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                    print("Deleted bet \(parlayID)")
                }
            }
        }
    }
    
    func deleteParlayModel(in context: NSManagedObjectContext, id: String, timestamp: Date) {
        let fetchRequest: NSFetchRequest<ParlayModel> = ParlayModel.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            if let entityToDelete = entities.first(where: {$0.id == id && $0.timestamp == timestamp}) {
                context.delete(entityToDelete)
                
                try context.save()
                print("Deleted parlay in local:", id)
            } else {
                print("Parlay not found or has been deleted.")
            }
        } catch {

        }
    }

    func makeParlay(for bets: [Bet], playerID: String, week: Int, leagueCode: String) -> Parlay {
        let parlay = Parlay(id: playerID + String(week), bets: bets, totalOdds: calculateParlayOdds(bets: bets), result: .pending, playerID: playerID, week: week, leagueCode: leagueCode, timestamp: Date(), deletedTimestamp: nil, isDeleted: false)
        return parlay
    }
    
    func updateParlayLeague(parlay: Parlay, leagueCode: String) {
        let newbet = db.collection("allParlays").document(parlay.id)
        newbet.updateData([
            "leagueID": leagueCode,
        ]) { err in
            if let err = err {
                print("Error updating LAYYY: \(err)", parlay.id)
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func createParlayModel(from parlay: Parlay, in context: NSManagedObjectContext) -> ParlayModel {
        let parlayModel = ParlayModel(context: context)
        
        parlayModel.id = parlay.id
        parlayModel.totalOdds = Int16(parlay.totalOdds)
        parlayModel.result = parlay.result.rawValue
        parlayModel.totalPoints = parlay.totalPoints
        parlayModel.betString = parlay.betString
        parlayModel.playerID = parlay.playerID
        parlayModel.week = Int16(parlay.week)
        parlayModel.leagueCode = parlay.leagueCode
        parlayModel.timestamp = parlay.timestamp
        
        for bet in parlay.bets {
            let betModel = BetModel(context: context)
            betModel.id = bet.betOption + bet.playerID + parlay.id + "parlayLeg"
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
            
            parlayModel.addToBets(betModel)
        }
        
        return parlayModel
    }
    
    func recreateParlay(parlay: ParlayModel, games: [GameModel], playerID: String, in context: NSManagedObjectContext) {
        func transformBetToDictionary(bet: BetModel) -> [String: Any] {
            return [
                "id": bet.betOption + bet.playerID + parlay.id + "parlayLeg",
                "betOption": bet.betOption,
                "game": bet.game.documentID ?? "",
                "type": bet.type,
                "odds": bet.odds,
                "result": bet.result,
                "selectedTeam": bet.selectedTeam ?? "",
                "week": parlay.week,
                "playerID": parlay.playerID,
                "leagueID": parlay.leagueCode,
                "timestamp": Timestamp(date: Date())
            ]
        }
        var newLayData = [String: Any]()
        if let betsArray = parlay.bets.allObjects as? [BetModel] {
            let betsDictionaryArray = betsArray.map(transformBetToDictionary)
            newLayData = [
                "isDeleted": true,
                "deletedTimestamp": Date(),
                "id": parlay.id + "deleted",
                "bets": betsDictionaryArray,
                "result": parlay.result,
                "totalOdds": parlay.totalOdds,
                "totalPoints": parlay.totalPoints,
                "playerID": parlay.playerID,
                "week": parlay.week,
                "leagueID": parlay.leagueCode,
                "timestamp": Timestamp(date: Date())
            ]
            let newLayID = parlay.id + "deleted"
            let newLay = self.db.collection("allParlays").document(newLayID)
            newLay.setData(newLayData) { err in
                if let err = err {
                    print("Error creating new parlay document: \(err)")
                } else {
                    print("Document successfully created with new ID")
                    print("Added new deleted parlay to cloud.")
                }
            }
        }
    }
    
    enum UpdateError: Error {
        case missingParlayID
        case firebaseError(Error)
    }

    func updateCloudParlayResults(parlays: [ParlayModel]) async throws {
        print("Starting parlay result updates...")
        
        for parlay in parlays {
            guard parlay.result == BetResult.pending.rawValue else { return }
            
            let parlayBets = parlay.bets.allObjects as? [BetModel] ?? []
            
            if !parlayBets.filter({ $0.game.betResult(for: $0).rawValue == BetResult.loss.rawValue }).isEmpty {
                updateCloudParlay(parlay: parlay, result: .loss, points: Int(-parlay.totalPoints))
            } else if parlayBets.filter({ $0.result == BetResult.win.rawValue }).count == parlayBets.count {
                updateCloudParlay(parlay: parlay, result: .win, points: Int(parlay.totalPoints))
            }
        }
    }
    
    func updateCloudParlay(parlay: ParlayModel, result: BetResult, points: Int) {
        let newParlay = db.collection("allParlays").document(parlay.id)
        newParlay.updateData([
            "result": result.rawValue,
            "totalPoints": points
        ]) { err in
            if let err = err {
                print("Error updating LAYYY: \(err)", parlay.id)
            } else {
                print("Lay successfully updated")
            }
        }
    }
    
    func updateLocalParlayResults(games: [GameModel], parlays: [ParlayModel], leagueCode: String, in context: NSManagedObjectContext) async throws {
        let updatedParlays = try await fetchParlays(games: games, leagueCode: leagueCode).filter({ $0.result != .pending })
        print("Starting local parlay result updates...")
        for parlay in parlays {
            if let newParlay = updatedParlays.first(where: {$0.id == parlay.id}) {
                parlay.result = newParlay.result.rawValue
                parlay.totalPoints = newParlay.result.rawValue == BetResult.push.rawValue ? 0 : newParlay.result.rawValue == BetResult.loss.rawValue ? -10 : newParlay.totalPoints
            }
        }
        do {
            try context.save()
            if !updatedParlays.isEmpty {
                print("\(updatedParlays.count) Parlay results successfully updated locally")
            }
        } catch {
            
        }
    }
}
