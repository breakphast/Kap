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
