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
    
    func updateUserPoints(user: User, bets: [Bet], parlays: [Parlay], week: Int, missing: Bool) {
        let newUser = db.collection("users").document(user.id!)
        
        let bets = bets.filter({ $0.playerID == user.id ?? "" && $0.result != .pending && $0.week == 2 })
        let parlay = parlays.filter({ $0.playerID == user.id ?? "" && $0.result != .pending && week == 2 })
        let points = bets.map { $0.points ?? 0 }.reduce(0, +) + (parlay.first?.totalPoints ?? 0)
                
        let dayTypeCounts: [DayType: Int] = [
            .sunday: 7,
            .mnf: 1,
            .snf: 1,
            .tnf: 1
        ]

        let totalMissedPoints: Double = dayTypeCounts.map { (dayType, expectedCount) in
            Double(expectedCount - bets.filter { $0.betOption.game.dayType == dayType.rawValue }.count) * -10.0
        }.reduce(0, +)
        
        let totalPoints = points + (missing ? totalMissedPoints : 0)
        
        newUser.updateData([
            "totalPoints": totalPoints
        ]) { err in
            if let err = err {
                print("Error updating USERRRR: \(err)")
            } else {
//                print("Document successfully updated")
            }
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
