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

    @NSManaged public var name: String?

}

extension BetModel : Identifiable {

}
