//
//  User.swift
//  Kap
//
//  Created by Desmond Fitch on 7/13/23.
//

import Foundation

class User {
    var userID: UUID
    var email: String
    var password: String
    var name: String
    var leagues: [League]
    
    init(userID: UUID, email: String, password: String, name: String, leagues: [League]) {
        self.userID = userID
        self.email = email
        self.password = password
        self.name = name
        self.leagues = leagues
    }
}
