//
//  NSManagedObject.swift
//  CoreDataObject
//
//  Created by Emre Eran on 13.03.2020.
//  Copyright © 2020 Emre Eran. All rights reserved.
//

import CoreData

public extension NSManagedObject {
    var stringID: String {
        objectID.string
    }

    func save(context: NSManagedObjectContext) throws -> Self {
        try context.save()
        return self
    }
}

public extension NSManagedObjectID {
    var string: String {
        uriRepresentation().absoluteString
    }
}
