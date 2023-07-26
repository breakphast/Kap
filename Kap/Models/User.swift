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
    var name: String
    var leagues: [String]  // Store league IDs the user is part of
}

struct Player {
    @DocumentID var id: String?
    let user: User
    let league: League
    var name: String
    var bets: [Bet]
    var parlays: [Parlay]
    var points: [Int: Int] = [0:0]
}
