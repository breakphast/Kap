import Foundation
import Firebase

class LeagueViewModel {
    
    private var db = Firestore.firestore()
    
    func fetchAllLeagues() async throws -> [League] {
        let querySnapshot = try await db.collection("leagues").getDocuments()

        let leagues: [League] = querySnapshot.documents.compactMap { document in
            try? document.data(as: League.self)
        }
        return leagues
    }
    
    func fetchLeaguesContainingID(id: String) async throws -> [League] {
        let querySnapshot = try await db.collection("leagues").getDocuments()

        let leagues: [League] = querySnapshot.documents.compactMap { document in
            guard let league = try? document.data(as: League.self),
                  league.players.contains(id) else {
                return nil
            }
            return league
        }
        return leagues
    }
    
    // CREATE: Create a new league
    func createNewLeague(league: League) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let data: [String: Any] = [
                "name": league.name,
                "players": league.players,
                "code": "\(Int.random(in: 1000 ... 9999))"
            ]

            let newLeagueDocument = db.collection("leagues").document()
            let leagueId = newLeagueDocument.documentID

            newLeagueDocument.setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: leagueId) // Return the new league's ID
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
