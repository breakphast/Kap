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
        
        for index in users.indices {
            users[index].avatar = index
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
    
    func fetchAllMissedBets(for userID: String, startingWeek: Int) async -> Int {
        for week in (1...startingWeek).reversed() {
            if let count = await fetchMissedBetsCount(for: userID, week: week) {
                print("Missed Bets for week\(week): \(count)")
                return count
            } else {
                print("No data for week\(week)")
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
