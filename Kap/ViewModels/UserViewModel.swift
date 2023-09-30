//
//  UserViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 7/25/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift

class UserViewModel: ObservableObject {
    @Published var user: User?
    private var db = Firestore.firestore()
    
    func fetchAllUsers() async throws -> [User] {
        let querySnapshot = try await db.collection("users").getDocuments()

        var users: [User] = querySnapshot.documents.compactMap { document in
            try? document.data(as: User.self)
        }
        
        let userCount = users.count
        for user in users {
            if user.avatar == nil {
                await updateAvatar(for: user.id!, avatar: userCount)
            }
        }

        // Refetch the users after updating avatars
        let updatedQuerySnapshot = try await db.collection("users").getDocuments()
        users = updatedQuerySnapshot.documents.compactMap { document in
            try? document.data(as: User.self)
        }

        return users
    }


    // Fetch user details
    func fetchUser(userId: String) {
        let docRef = db.collection("users").document(userId)

        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
            } else if let document = document, document.exists {
                if let user = try? document.data(as: User.self) {
                    self.user = user
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    // Update user details
    func updateUser(user: User) {
        do {
            try db.collection("users").document(user.id ?? "").setData(from: user)
        } catch let error {
            print("Error updating user: \(error)")
        }
    }
    
    func fetchMissedBetsCount(for userID: String, week: Int) async -> Int? {
        let weekDocumentID = "week\(week)"
        let userDocument = db.collection("users").document(userID)
        
        do {
            let document = try await userDocument.collection("missedBets").document(weekDocumentID).getDocument()
            if let missedBet = try? document.data(as: MissedBet.self) {
                return missedBet.missedCount
            }
        } catch {
            print("Error fetching missed bets for \(weekDocumentID): \(error)")
        }
        return nil
    }
    
    func updateMissedBetsCount(for userID: String, week: Int, newValue: Int) async {
        let weekDocumentID = "week\(week)"
        let userDocument = db.collection("users").document(userID)
        let missedBetsDocument = userDocument.collection("missedBets").document(weekDocumentID)

        do {
            try await missedBetsDocument.setData(["missedCount": newValue], merge: true)
            print("Successfully updated missed bets count")
        } catch {
            print("Error updating missed bets count for \(weekDocumentID): \(error)")
        }
    }
    
    func updateAvatar(for userID: String, avatar: Int) async {
        let userDocument = db.collection("users").document(userID)
        do {
            try await userDocument.setData(["avatar": avatar], merge: true)
            print("Successfully updated avatar")
        } catch {
            
        }
    }
    
    func updateLeagues(for userID: String, leagueID: String) async {
        let userDocument = db.collection("users").document(userID)
        let leagueDocument = userDocument.collection("leagues").document(leagueID)

        do {
            try await leagueDocument.setData(["id": leagueID], merge: true)
            print("Successfully updated leagues")
        } catch {
            print("Error updating missed bets count for \(leagueDocument.documentID): \(error)")
        }
    }
    
    
    
    func fetchUserLeagues(for userID: String, leagueID: String) async -> [String: Any]? {
        let userDocument = db.collection("users").document(userID)
        let leagueDocument = userDocument.collection("leagues").document(leagueID)
        
        do {
            let document = try await leagueDocument.getDocument()
            if let leagueData = document.data() {
                return leagueData
            } else {
                print("Document does not exist")
            }
        } catch {
            print("Error fetching league data for \(leagueDocument.documentID): \(error)")
        }
        
        return nil
    }

    
    func fetchAllMissedBets(for userID: String, startingWeek: Int) async -> Int {
        for week in (1...startingWeek).reversed() {
            if let count = await fetchMissedBetsCount(for: userID, week: week) {
                return count
            }
        }
        return 0
    }
    
    func updateUserPoints(user: User, bets: [Bet], parlays: [Parlay], week: Int, missing: Bool) async {
        guard let userID = user.id else {
            print("User ID is nil")
            return
        }

        let newUser = db.collection("users").document(userID)
        
        var totalPoints: Double = 0
        var totalMissedBets: Int = 0
        
        for currentWeek in 1...week {
            // Filter bets for the current user and the currentWeek
            let userBets = bets.filter { $0.playerID == userID && $0.week == currentWeek }
            let settledBets = userBets.filter { $0.result != .pending && $0.result != .push }
            let parlay = parlays.first(where: { $0.playerID == userID && $0.result != .pending && $0.week == currentWeek })

            let points = settledBets.map { $0.points ?? 0 }.reduce(0, +) + (parlay?.totalPoints ?? 0)
            
            totalPoints += points
            totalMissedBets += await fetchMissedBetsCount(for: userID, week: currentWeek) ?? 0
        }
        do {
            totalPoints += Double(totalMissedBets) * -10.0
            try await newUser.updateData(["totalPoints": totalPoints])
            print("User successfully updated")
        } catch {
            print("Error updating USERRRR: \(error)")
        }
    }

    // Add a new user
    func addUser(user: User) {
        do {
            let _ = try db.collection("users").addDocument(from: user)
        } catch let error {
            print("Error adding user: \(error)")
        }
    }
    
    // Delete a user
    func deleteUser(userId: String) {
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("Error removing user: \(error)")
            } else {
                print("User successfully removed!")
            }
        }
    }
}
