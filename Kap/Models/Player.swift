//
//  Player.swift
//  Kap
//
//  Created by Desmond Fitch on 7/26/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Player {
    @DocumentID var id: String?
    let user: User
    let leagueCode: String
    var name: String
    var bets: [Bet]
    var parlays: [Parlay]
    var points: [Int: Int] = [0:0]
    var totalPoints: Int = 0
}
