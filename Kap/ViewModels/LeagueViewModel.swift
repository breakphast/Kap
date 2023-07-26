import Foundation
import Firebase

class LeagueViewModel {
    
    private var db = Firestore.firestore()
    
    // CREATE: Create a new league
    func createNewLeague(league: League) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("leagues").addDocument(data: [
                "name": league.name,
                "players": league.players
            ]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: "League created successfully")
                }
            }
        }
    }
    
    // UPDATE: Add player (a Player's ID) to a league
    func addPlayerToLeague(leagueId: String, playerId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("leagues").document(leagueId).updateData([
                "players": FieldValue.arrayUnion([playerId])
            ]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // CREATE: Create a player from a user's ID
    func createPlayerFromUserId(userId: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let newDocument = db.collection("players").document()
            let playerData: [String: Any] = ["user": ["id": userId]]
            
            newDocument.setData(playerData) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: newDocument.documentID)
                }
            }
        }
    }
    
    // DELETE: Delete a league
    func deleteLeague(leagueId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("leagues").document(leagueId).delete() { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
