//
//  AuthViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI
import Firebase

class AuthViewModel: ObservableObject {
    var userSession: FirebaseAuth.User? = nil
    var didAuthenticateUser = false
    var currentUser: User?
    
    private let service = UserService()
    
    private var tempUserSession: FirebaseAuth.User?
    
    let auth = Auth.auth()
    
    func fetchUser() {
        guard let uid = self.userSession?.uid else { return } // always current user
        print(uid)
        
        service.fetchUser(withUid: uid) { user in
            self.currentUser = user // sets published user to user we fetched from database
        }
        print(self.currentUser == nil)
    }
    
    func login(withEmail email: String, password: String, completion: @escaping (String?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Failed to sign in: \(error)")
                completion(nil)
                return
            }
            
            guard let user = result?.user else { 
                completion(nil)
                return
            }
            self.userSession = user
            self.fetchUser()
            completion(user.uid)
            print("Successfully logged in user.")
        }
    }
    
    func register(withEmail email: String, password: String, username: String, fullName: String, userCount: Int) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Failed to register: \(error)")
                return
            }
            
            guard let user = result?.user else { return }
            self.tempUserSession = user
            
            let data: [String: Any] = [
                "id": user.uid,
                "email": email,
                "password": password,
                "username": username,
                "fullName": fullName
            ]
            
            Firestore.firestore().collection("users")
                .document(user.uid)
                .setData(data) { _ in
                    self.didAuthenticateUser = true
                }
        }
    }
    
    func signOut() {
        userSession = nil
        try? auth.signOut()
        print("Signed out")
        currentUser = nil
        didAuthenticateUser = false
        tempUserSession = nil
    }
}
