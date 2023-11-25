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
}

extension BetOptionModel : Identifiable {

}

extension BetOptionModel {
    func update(with betOption: BetOption) {
        self.id = betOption.id
        self.odds = Int16(betOption.odds)
        self.spread = betOption.spread ?? 0
        self.over = betOption.over
        self.under = betOption.under
        self.betType = betOption.betType.rawValue
        self.selectedTeam = betOption.selectedTeam
        self.confirmBet = betOption.confirmBet
        self.maxBets = Int16(betOption.maxBets ?? 0)
        // self.game = game // This is set outside this function
        self.betString = betOption.betString
    }
}
