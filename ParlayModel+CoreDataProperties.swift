//
//  ParlayModel+CoreDataProperties.swift
//  Kap
//
//  Created by Desmond Fitch on 10/26/23.
//
//

import Foundation
import CoreData


extension ParlayModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ParlayModel> {
        return NSFetchRequest<ParlayModel>(entityName: "ParlayModel")
    }

    @NSManaged public var betString: String?
    @NSManaged public var id: String?
    @NSManaged public var leagueCode: String?
    @NSManaged public var playerID: String?
    @NSManaged public var result: String?
    @NSManaged public var totalOdds: Int16
    @NSManaged public var totalPoints: Double
    @NSManaged public var week: Int16
    @NSManaged public var bets: NSSet?
    @NSManaged public var timestamp: Date?

}

// MARK: Generated accessors for bets
extension ParlayModel {

    @objc(addBetsObject:)
    @NSManaged public func addToBets(_ value: BetModel)

    @objc(removeBetsObject:)
    @NSManaged public func removeFromBets(_ value: BetModel)

    @objc(addBets:)
    @NSManaged public func addToBets(_ values: NSSet)

    @objc(removeBets:)
    @NSManaged public func removeFromBets(_ values: NSSet)

}

extension ParlayModel : Identifiable {

}
