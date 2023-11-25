//
//  GameModel+CoreDataProperties.swift
//  Kap
//
//  Created by Desmond Fitch on 10/19/23.
//
//

import Foundation
import CoreData


extension GameModel {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GameModel> {
        return NSFetchRequest<GameModel>(entityName: "GameModel")
    }

    @NSManaged public var id: String?
    @NSManaged public var documentID: String?
    @NSManaged public var homeTeam: String?
    @NSManaged public var awayTeam: String?
    @NSManaged public var date: Date
    @NSManaged public var homeSpread: Double
    @NSManaged public var awaySpread: Double
    @NSManaged public var homeMoneyLine: Int16
    @NSManaged public var awayMoneyLine: Int16
    @NSManaged public var over: Double
    @NSManaged public var under: Double
    @NSManaged public var completed: Bool
    @NSManaged public var homeScore: String?
    @NSManaged public var awayScore: String?
    @NSManaged public var homeSpreadPriceTemp: Double
    @NSManaged public var awaySpreadPriceTemp: Double
    @NSManaged public var overPriceTemp: Double
    @NSManaged public var underPriceTemp: Double
    @NSManaged public var week: Int16
    @NSManaged public var betOptions: NSSet?
//    @NSManaged public var betOptions: BetOptionModel?

}

extension GameModel : Identifiable {

}

extension GameModel {

    // Accessor methods for betOptions relationship
    @objc(addBetOptionsObject:)
    @NSManaged public func addToBetOptions(_ value: BetOptionModel)

    @objc(removeBetOptionsObject:)
    @NSManaged public func removeFromBetOptions(_ value: BetOptionModel)

    @objc(addBetOptions:)
    @NSManaged public func addToBetOptions(_ values: NSSet)

    @objc(removeBetOptions:)
    @NSManaged public func removeFromBetOptions(_ values: NSSet)

    func update(with newGame: Game) {
        self.homeSpread = newGame.homeSpread
        self.awaySpread = newGame.awaySpread
        self.homeMoneyLine = Int16(newGame.homeMoneyLine)
        self.awayMoneyLine = Int16(newGame.awayMoneyLine)
        self.over = newGame.over
        self.under = newGame.under
        self.homeSpreadPriceTemp = newGame.homeSpreadPriceTemp
        self.awaySpreadPriceTemp = newGame.awaySpreadPriceTemp
        self.overPriceTemp = newGame.overPriceTemp
        self.underPriceTemp = newGame.underPriceTemp
        self.betOptions = [] // Assuming you want to reset this each time
        self.homeScore = newGame.homeScore
        self.awayScore = newGame.awayScore
        self.completed = newGame.completed
    }
}
