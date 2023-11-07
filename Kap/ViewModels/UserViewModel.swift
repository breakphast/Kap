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
    
    func fetchAllUsers(leagueUsers: [String]) async throws -> [User] {
        guard leagueUsers.count <= 10 else {
            throw CustomError.exceededLimit
        }

        let querySnapshot = try await db.collection("users").whereField("id", in: leagueUsers).getDocuments()

        let users: [User] = querySnapshot.documents.compactMap { document in
            try? document.data(as: User.self)
        }
        
        let userCount = users.count
        for user in users {
            if user.avatar == nil {
                await updateAvatar(for: user.id!, avatar: userCount)
            }
        }

        // No need to refetch users since we've updated the avatars in place
        return users
    }

    enum CustomError: Error {
        case exceededLimit
    }

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
    
    func updateAvatar(for userID: String, avatar: Int) async {
        let userDocument = db.collection("users").document(userID)
        do {
            try await userDocument.setData(["avatar": avatar], merge: true)
            print("Successfully updated avatar")
        } catch {
            
        }
    }
    
    func updateLeagues(for userID: String, leagueCode: String) async {
        let userDocument = db.collection("users").document(userID)
        let leagueDocument = userDocument.collection("leagues").document(leagueCode)

        do {
            try await leagueDocument.setData(["id": leagueCode], merge: true)
            print("Successfully updated leagues")
        } catch {
            print("Error updating missed bets count for \(leagueDocument.documentID): \(error)")
        }
    }
    
    func fetchUserLeagues(for userID: String, leagueCode: String) async -> [String: Any]? {
        let userDocument = db.collection("users").document(userID)
        let leagueDocument = userDocument.collection("leagues").document(leagueCode)
        
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
