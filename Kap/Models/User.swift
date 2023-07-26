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

//@Observable class Player {
//    let id: UUID
//    let user: User
//    let league: League
//    var name: String
//    var bets: [[Bet]]
//    var parlays: [Parlay]
//    var points: [Int: Int]
//    
//    init(id: UUID, user: User, league: League, name: String, bets: [[Bet]], parlays: [Parlay], points: [Int: Int]) {
//        self.id = id
//        self.user = user
//        self.league = league
//        self.name = name
//        self.bets = bets
//        self.parlays = parlays
//        self.points = Dictionary(uniqueKeysWithValues: (0...16).map { ($0, 0) })
//    }
//}
