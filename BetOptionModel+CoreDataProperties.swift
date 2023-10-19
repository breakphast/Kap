//
//  BetOptionModel+CoreDataProperties.swift
//  Kap
//
//  Created by Desmond Fitch on 10/19/23.
//
//

import Foundation
import CoreData


extension BetOptionModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BetOptionModel> {
        return NSFetchRequest<BetOptionModel>(entityName: "BetOptionModel")
    }

    @NSManaged public var id: String?
    @NSManaged public var odds: Int16
    @NSManaged public var spread: Double
    @NSManaged public var over: Double
    @NSManaged public var under: Double
    @NSManaged public var betString: String?
    @NSManaged public var selectedTeam: String?
    @NSManaged public var confirmBet: Bool
    @NSManaged public var maxBets: Int16
    @NSManaged public var betType: String?
    @NSManaged public var dayType: String?
    @NSManaged public var game: GameModel?
    
    var betTypeEnum: BetType {
        get {
            // Attempt to get a valid enum from the raw value stored in Core Data
            // We're assuming "betType" is the name of the Core Data attribute
            return BetType(rawValue: betType ?? "") ?? .spread // Provide a default just in case
        }
        set(newBetType) {
            // Save the raw value of the enum to Core Data
            betType = newBetType.rawValue
        }
    }

    // Similar computed properties would be used for other enum attributes like dayType
    var dayTypeEnum: DayType {
        get {
            return DayType(rawValue: dayType ?? "") ?? .sunday // Default value as an example
        }
        set(newDayType) {
            dayType = newDayType.rawValue
        }
    }

}

extension BetOptionModel : Identifiable {

}
