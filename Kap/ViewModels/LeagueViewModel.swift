import Foundation
import Firebase

class LeagueViewModel: ObservableObject {
    @Published var points = [String: Double]()
    @Published var activeLeague: League?
    
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
                  ((league.players?.contains(id)) != nil) else {
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
    
    func addPointsToLeague(leagueId: String, points: Double, forKey key: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let docRef = db.collection("leagues").document(leagueId)
            
            docRef.getDocument { (document, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let document = document, document.exists, var pointsDictionary = document.get("points") as? [String: Double] else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Document does not exist or points dictionary is missing/invalid"])
                    continuation.resume(throwing: error)
                    return
                }
                
                pointsDictionary[key, default: 0] += points
                
                docRef.updateData(["points": pointsDictionary]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
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
