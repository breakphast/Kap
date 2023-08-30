//
//  User.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var username: String
    var fullName: String?
    var leagues: [String]?  // Store league IDs the user is part of
    var totalPoints: Double?
    var avatar: Int?
}
