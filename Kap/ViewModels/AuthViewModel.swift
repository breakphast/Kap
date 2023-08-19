//
//  AuthViewModel.swift
//  Kap
//
//  Created by Desmond Fitch on 8/17/23.
//

import SwiftUI
import Firebase
import Observation
import SwiftData

@Observable class AuthViewModel {
    var userSession: FirebaseAuth.User? = nil
    var didAuthenticateUser = false
    var currentUser: User? // optional because we have to reach out to our api to get data before we set it so it will originally be nil... app launches before we fetch the data
    
    private let service = UserService()
    
    private var tempUserSession: FirebaseAuth.User?
    
    let auth = Auth.auth()
    
    init() {
        self.userSession = Auth.auth().currentUser
        self.fetchUser() // from auth view model
    }
    
    func fetchUser() {
        guard let uid = self.userSession?.uid else { return } // always current user
        
        service.fetchUser(withUid: uid) { user in
            self.currentUser = user // sets published user to user we fetched from database
        }
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
            print(user.uid)
            completion(user.uid)
            print("Successfully logged in user.")
        }
    }
    
    func register(withEmail email: String, password: String, username: String, fullName: String) {
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
                    print("Set to true")
                }
        }
    }
    
    func signOut() {
        userSession = nil
        try? auth.signOut()
        print("Signed out")
    }
    
//    func uploadProfileImage(_ image: UIImage) {
//        guard let uid = tempUserSession?.uid else { return }
//        
//        ImageUploader.uploadImage(image: image) { profileImageURL in
//            Firestore.firestore().collection("users")
//                .document(uid)
//                .updateData(["imageProfileURL": profileImageURL]) { _ in
//                    self.userSession = self.tempUserSession
//                    self.fetchUser()
//                }
//        }
//    }
    
//    func updateProfileImage(_ image: UIImage, completion: @escaping() -> Void) {
//        guard let uid = Auth.auth().currentUser?.uid else { return }
//        
//        ImageUploader.uploadImage(image: image) { profileImageURL in
//            Firestore.firestore().collection("users")
//                .document(uid)
//                .updateData(["imageProfileURL": profileImageURL]) { _ in
//                    completion()
//                }
//        }
//    }
    
}
