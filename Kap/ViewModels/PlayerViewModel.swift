//
//  PlayerViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import Foundation
import Firebase

class PlayerViewModel {
    
    private var db = Firestore.firestore()
    
    // READ: Fetch a player by their ID
    func fetchPlayer(playerId: String) async throws -> Player? {
        let document = db.collection("players").document(playerId)
        
        return try await withCheckedThrowingContinuation { continuation in
            document.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                    // Convert data dictionary to Player instance.
                    if let player = Player(data: data) {
                        continuation.resume(returning: player)
                    } else {
                        continuation.resume(throwing: NSError(domain: "PlayerViewModel", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to convert snapshot to Player"]))
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func addPlayer(player: Player) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            var newDocument = db.collection("players").document()
            var playerData = [
                "name": player.name,
                "user": ["id": player.user.id ?? ""],
                "league": ["id": player.league.id ?? ""]
            ] as [String: Any]
            
            newDocument.setData(playerData) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: newDocument.documentID)
                }
            }
        }
    }
    
    // UPDATE: Update a player's data
    func updatePlayer(player: Player) async throws {
        guard let playerId = player.id else {
            throw NSError(domain: "PlayerViewModel", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid player ID"])
        }
        
        let playerData: [String: Any] = [
            "name": player.name,
            "user": ["id": player.user.id ?? ""],
            "league": ["id": player.league.id ?? ""]
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("players").document(playerId).setData(playerData, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // DELETE: Delete a player by their ID
    func deletePlayer(playerId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("players").document(playerId).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

// Conversion from dictionary to Player model (assuming necessary initializers are present in the model)
extension Player {
    init?(data: [String: Any]) {
        guard let name = data["name"] as? String,
              let userId = (data["user"] as? [String: Any])?["id"] as? String,
              let leagueId = (data["league"] as? [String: Any])?["id"] as? String
        else {
            return nil
        }
        
        self.name = name
        self.user = User(id: userId, email: "", name: "", leagues: [])  // You'd likely want to fetch more user data here or adjust the structure.
        self.league = League(id: leagueId, name: "", players: [])  // Similarly, you'd want to fetch more league data or adjust.
        self.bets = []
        self.parlays = []
        self.points = [:]
    }
}

