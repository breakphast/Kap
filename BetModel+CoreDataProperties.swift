//
//  BetModel+CoreDataProperties.swift
//  Kap
//
//  Created by Desmond Fitch on 10/18/23.
//
//

import Foundation
import CoreData


extension BetModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BetModel> {
        return NSFetchRequest<BetModel>(entityName: "BetModel")
    }

    @NSManaged public var id: String
    @NSManaged public var betOption: String
    @NSManaged public var game: GameModel
    @NSManaged public var type: String
    @NSManaged public var result: String
    @NSManaged public var odds: Int16
    @NSManaged public var points: Double
    @NSManaged public var stake: Double
    @NSManaged public var betString: String
    @NSManaged public var selectedTeam: String?
    @NSManaged public var playerID: String
    @NSManaged public var week: Int16
    @NSManaged public var leagueCode: String
    @NSManaged public var betOptionString: String

}

extension BetModel : Identifiable {

}
