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
    
    func updateUserPoints(user: User, bets: [Bet], parlays: [Parlay], week: Int, missing: Bool) async {
        guard let userID = user.id else {
            print("User ID is nil")
            return
        }

        let newUser = db.collection("users").document(userID)

        // Filter bets for the current user and the given week
        let userBets = bets.filter { $0.playerID == userID && $0.week == week }
        let settledBets = userBets.filter { $0.result != .pending && $0.result != .push}
        let parlay = parlays.first(where: { $0.playerID == userID && $0.result != .pending && $0.week == week })

        let points = settledBets.map { $0.points ?? 0 }.reduce(0, +) + (parlay?.totalPoints ?? 0)
        
        var totalPoints = points
        totalPoints += Double(await fetchMissedBetsCount(for: userID, week: week) ?? 0) * -10.0
        do {
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


//func updateUserPoints(user: User, bets: [Bet], parlays: [Parlay], week: Int, missing: Bool) {
//    guard let userID = user.id else {
//        print("User ID is nil")
//        return
//    }
//
//    let newUser = db.collection("users").document(userID)
//
//    // Filter bets for the current user and the given week
//    let userBets = bets.filter { $0.playerID == userID && $0.week == week }
//    let settledBets = userBets.filter { $0.result != .pending }
////        let unsettledBets = userBets.filter { $0.result == .pending }
//    let parlay = parlays.first(where: { $0.playerID == userID && $0.result != .pending && $0.week == week })
//
//    let points = settledBets.map { $0.points ?? 0 }.reduce(0, +) + (parlay?.totalPoints ?? 0)
//
//    var totalPoints = points
//
//    Task {
//        await totalPoints += Double(fetchMissedBetsCount(for: userID, week: week) ?? 0) * -10.0
//    }
//
//    let weekDocumentID = "week\(week)"
//    let missedBetDocument = newUser.collection("missedBets").document(weekDocumentID)
//
//    let ok = user.missedBets?.count
//    print(ok ?? "fefeee")
//
////        missedBetDocument.getDocument { document, error in
////            if let doc = document, doc.exists, let missedBet = try? doc.data(as: MissedBet.self) {
////                // Increment missedCount by 1 and update the document
////                missedBetDocument.setData([
////                    "week": weekDocumentID,
////                    "missedCount": missedBet.missedCount + 1
////                ], merge: true)
////            } else {
////                // Create a new missedBet document for this week
////                missedBetDocument.setData([
////                    "week": weekDocumentID,
////                    "missedCount": 1
////                ])
////            }
////        }
//
//    newUser.updateData([
//        "totalPoints": totalPoints
//    ]) { err in
//        if let err = err {
//            print("Error updating USERRRR: \(err)")
//        } else {
//            print("User successfully updated")
//        }
//    }
//
//}
