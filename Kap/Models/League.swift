//
//  League.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct League: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var players: [String]
    var code: String
    var points: [String: Double]
//    var bets: [Bet] = []
//    var parlays: [Parlay] = []
//    var leaderboards: [[Player]] = [[]]
}
