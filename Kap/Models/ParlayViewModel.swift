//  ParlayViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import Foundation
import Firebase
import FirebaseFirestore

class ParlayViewModel {
    private let db = Firestore.firestore()
    
    func fetchParlays(games: [Game]) async throws -> [Parlay] {
        let querySnapshot = try await db.collection("parlays").getDocuments()
        let parlays = querySnapshot.documents.compactMap { queryDocumentSnapshot -> Parlay? in
            let data = queryDocumentSnapshot.data()
            guard
                let id = data["id"] as? String,
                let betsData = data["bets"] as? [[String: Any]],
                let totalOdds = data["totalOdds"] as? Int,
                let resultString = data["result"] as? String,
                let result = BetResult(rawValue: resultString),
                let betString = data["betString"] as? String,
                let playerID = data["playerID"] as? String,
                let week = data["week"] as? Int,
                let leagueCode = data["leagueID"] as? String
            else { return nil }
            var bets = [Bet]()
            for betData in betsData {
                guard
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
                    let bet = Bet(id: betOptionID + playerID, betOption: betOptionID, game: foundGame, type: type, result: result, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode)
                    bets.append(bet)
                }
            }
            let parlay = Parlay(id: id, bets: bets, totalOdds: totalOdds, result: result, playerID: playerID, week: week, leagueCode: leagueCode)
            parlay.totalOdds = totalOdds
            parlay.betString = betString
            
            return parlay
        }
        return parlays
    }
    
    func addParlay(parlay: Parlay) async throws {
        var newParlay: [String: Any] = [
            "id": parlay.id,
            "bets": parlay.bets.map { bet in
                [
                    "betOption": bet.betOption,
                    "game": bet.game.documentId,
                    "type": bet.type.rawValue,
                    "odds": bet.odds,
                    "result": bet.result?.rawValue ?? "",
                    "selectedTeam": bet.selectedTeam ?? "",
                    "week": parlay.week,
                    "playerID": parlay.playerID,
                    "leagueID": parlay.leagueCode
                ] as [String : Any]
            },
            "result": parlay.result.rawValue,
            "totalOdds": parlay.totalOdds,
            "totalPoints": parlay.totalPoints,
            "playerID": parlay.playerID,
            "week": parlay.week
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

//        let _ = try await db.collection("parlays").addDocument(data: newParlay)
        let _ = try await db.collection("parlays").document(parlay.id).setData(newParlay)
    }
    
    func deleteParlay(parlayID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("parlays").document(parlayID).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                    print("Deleted bet \(parlayID)")
                }
            }
        } 
    }
    
    func makeParlay(for bets: [Bet], playerID: String, week: Int, leagueCode: String) -> Parlay {
        let parlay = Parlay(id: playerID + String(week), bets: bets, totalOdds: calculateParlayOdds(bets: bets), result: .pending, playerID: playerID, week: week, leagueCode: leagueCode)
        return parlay
    }
    
    func updateParlayLeague(parlay: Parlay, leagueCode: String) {
        let newbet = db.collection("parlays").document(parlay.id)
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
}
