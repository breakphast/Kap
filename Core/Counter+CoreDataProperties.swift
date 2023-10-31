//
//  Counter+CoreDataProperties.swift
//  Kap
//
//  Created by Desmond Fitch on 10/24/23.
//
//

import Foundation
import CoreData


extension Counter {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Counter> {
        return NSFetchRequest<Counter>(entityName: "Counter")
    }

    @NSManaged public var betCount: Int16
    @NSManaged public var timestamp: Date?

}

extension Counter : Identifiable {

}
