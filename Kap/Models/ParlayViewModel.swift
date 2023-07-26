//  ParlayViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import Foundation
import Firebase

class ParlayViewModel {
    private let db = Firestore.firestore()

    func fetchParlays(games: [Game]) async throws -> [Parlay] {
        let querySnapshot = try await db.collection("parlays").getDocuments()
        let parlays = querySnapshot.documents.compactMap { queryDocumentSnapshot -> Parlay? in
            let data = queryDocumentSnapshot.data()

            guard
                let id = data["id"] as? String,
                let betsData = data["bets"] as? [[String: Any]],
                let resultString = data["result"] as? String,
                let result = BetResult(rawValue: resultString)
            else { return nil }

            var bets = [Bet]()
            for betData in betsData {
                guard
                    let gameID = betData["game"] as? String,
                    let betOptionID = betData["betOption"] as? String,
                    let typeString = betData["type"] as? String,
                    let type = BetType(rawValue: typeString),
                    let odds = betData["odds"] as? Int,
                    let selectedTeam = betData["selectedTeam"] as? String
                else { continue }
                
                let (foundGame, foundBetOption) = BetViewModel().findBetOption(games: games, gameID: gameID, betOptionID: betOptionID)
                if let foundGame = foundGame, let foundBetOption = foundBetOption {
                    let bet = Bet(id: UUID(uuidString: id)!, betOption: foundBetOption, game: foundGame, type: type, result: result, odds: odds, selectedTeam: selectedTeam)
                    bets.append(bet)
                }
            }

            return Parlay(id: UUID(uuidString: id)!, bets: bets, result: result)
        }
        
        return parlays
    }

    func addParlay(parlay: Parlay) async throws {
        let newParlay: [String: Any] = [
            "id": UUID().uuidString,
            "bets": parlay.bets.map { bet in
                [
                    "betOption": bet.betOption.id.uuidString,
                    "game": bet.game.id,
                    "type": bet.type.rawValue,
                    "odds": bet.odds,
                    "result": bet.result?.rawValue ?? "",
                    "selectedTeam": bet.selectedTeam ?? ""
                ]
            },
            "result": parlay.result.rawValue,
            "totalOdds": parlay.totalOdds,
            "totalPoints": parlay.totalPoints,
            "betString": parlay.betString
        ]

        let _ = try await db.collection("parlays").addDocument(data: newParlay)
    }
    
    func makeParlay(for bets: [Bet]) -> Parlay {
        let parlay = Parlay(id: UUID(), bets: bets, result: .pending)
        return parlay
    }
}
