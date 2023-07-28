//
//  BetViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import Foundation
import FirebaseFirestoreSwift
import Firebase

class BetViewModel {
    private let db = Firestore.firestore()
    
    func findBetOption(games: [Game], gameID: String, betOptionID: String) -> (Game?, BetOption?) {
        guard let game = games.first(where: { $0.id == gameID }) else {
            print("No game")
            return (nil, nil) }
        
        guard let betOption = game.betOptions.first(where: { $0.id.uuidString == betOptionID }) else { return (game, nil) }
        
        return (game, betOption)
    }
    
    func stringToBetType(_ typeString: String) -> BetType? {
        return BetType(rawValue: typeString)
    }
    
    func stringToBetResult(_ resultString: String) -> BetResult? {
        return BetResult(rawValue: resultString)
    }
    
    func fetchBets(games: [Game]) async throws -> [Bet] {
        let querySnapshot = try await db.collection("bets").getDocuments()
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
            let (foundGame, foundBetOption) = self.findBetOption(games: games, gameID: game, betOptionID: betOption)
            
            let bet = Bet(id: UUID(uuidString: id)!, betOption: foundBetOption!, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week)
            
            return bet
        }
        return bets
    }
    
    func addBet(bet: Bet) async throws {
        let db = Firestore.firestore()
        
        let newBet: [String: Any] = [
            "id": bet.id.uuidString,
            "betOption": bet.betOption.id.uuidString,
            "game": bet.game.id,
            "type": bet.type.rawValue,
            "result": bet.result?.rawValue ?? "",
            "odds": bet.odds,
            "points": bet.points ?? 0,
            "stake": 100,
            "betString": bet.betString,
            "selectedTeam": bet.selectedTeam ?? "",
            "playerID": bet.playerID,
            "week": bet.week
        ]
        
        let _ = try await db.collection("bets").document(bet.id.uuidString).setData(newBet)
    }

    
    func makeBet(for game: Game, betOption: BetOption, playerID: String, week: Int) -> Bet {
        let bet = Bet(id: UUID(), betOption: betOption, game: game, type: betOption.betType, result: [.pending, .loss, .win].randomElement(), odds: betOption.odds, selectedTeam: betOption.selectedTeam, playerID: playerID, week: week)
        
        return bet
    }
    
    func deleteBet(betID: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("bets").document(betID).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                    print("Deleted bet \(betID)")
                }
            }
        }
    }
    
    func generateBetsForGame(_ game: Game) -> [Bet] {
        var bets = [Bet]()
        let options = [0, 2, 4, 1, 3, 5].compactMap { index in
            game.betOptions.indices.contains(index) ? game.betOptions[index] : nil
        }
        for i in 0..<6 {
            var type = BetType.moneyline
            switch i {
            case 0, 3:
                type = .spread
            case 1, 4:
                type = .moneyline
            case 2:
                type = .over
            case 5:
                type = .under
            default:
                type = .moneyline
            }
            var team = ""
            switch i {
            case 3, 2, 4:
                team = game.awayTeam
            default:
                team = game.homeTeam
            }
            
            let bet = Bet(id: UUID(), betOption: options[i], game: game, type: type, result: .pending, odds: options[i].odds, selectedTeam: team, playerID: "", week: 0)
            bets.append(bet)
        }
        let betss = [3, 4, 2, 0, 1, 5].compactMap { index in
            bets.indices.contains(index) ? bets[index] : nil
        }
        return betss
    }
}
