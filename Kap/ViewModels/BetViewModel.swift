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

class BetViewModel: ObservableObject {
    @Published var fireBets = [Bet]()
    @Published var allBets = [Bet]()
    @Published var leagueBets = [Bet]()
    
    let db = Firestore.firestore()
    
    func fetchBets(games: [Game], leagueCode: String) async throws -> [Bet] {
        let querySnapshot = try await db.collection("newBets").whereField("leagueID", isEqualTo: leagueCode)  .getDocuments()
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
            
            let bet = Bet(id: id, betOption: betOption, game: foundGame!, type: BetType(rawValue: type)!, result: self.stringToBetResult(result)!, odds: odds, selectedTeam: selectedTeam, playerID: playerID, week: week, leagueCode: leagueID)
            
            return bet
        }
        return bets
    }


    func findBetGame(games: [Game], gameID: String) -> Game? {
        guard let game = games.first(where: { $0.documentId == gameID }) else {
            print("No game")
            return nil }
        
        return game
    }
    
    func stringToBetType(_ typeString: String) -> BetType? {
        return BetType(rawValue: typeString)
    }
    
    func stringToBetResult(_ resultString: String) -> BetResult? {
        return BetResult(rawValue: resultString)
    }
    
    func addBet(bet: Bet, playerID: String) async throws {
        let db = Firestore.firestore()
        
        let newBet: [String: Any] = [
            "id": bet.id,
            "betOption": bet.betOption,
            "game": bet.game.documentId,
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
            "datePlaced": "\(Date())"
        ]
        
        let _ = try await db.collection("newBets").document(bet.id).setData(newBet)
    }
    
    func makeBet(for game: Game, betOption: String, playerID: String, week: Int, leagueCode: String) -> Bet? {
        if let option = game.betOptions.first(where: { $0.id == betOption }) {
            let bet = Bet(id: betOption + playerID + leagueCode, betOption: betOption, game: game, type: option.betType, result: .pending, odds: option.odds, selectedTeam: option.selectedTeam, playerID: playerID, week: week, leagueCode: leagueCode)
            return bet
        }
                                           
        return nil
    }
    
    func updateBet(bet: Bet) {
        let newbet = db.collection("newBets").document(bet.id)
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
    
    func updateBetLeague(bet: Bet, leagueCode: String) {
        let newbet = db.collection("newBets").document(bet.id)
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
        
        let newbet = db.collection("newBets").document(bet.id)
        if let newPoints = bet.points {
            newbet.updateData([
                "result": result.rawValue,
                "points": result == .push ? 0 : newPoints * (result == .win ? 1 : -1)
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
            db.collection("newBets").document(betID).delete() { error in
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
            
            let bet = Bet(id: options[i].id, betOption: options[i].id, game: game, type: type, result: .pending, odds: options[i].odds, selectedTeam: team, playerID: "", week: 0, leagueCode: "")
            bets.append(bet)
        }
        let betss = [3, 4, 2, 0, 1, 5].compactMap { index in
            bets.indices.contains(index) ? bets[index] : nil
        }
        return betss
    }
}
