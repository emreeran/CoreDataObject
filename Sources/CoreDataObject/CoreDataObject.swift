//
//  CoreDataObject.swift
//  CoreDataSample
//
//  Created by Emre Eran on 11.03.2020.
//  Copyright © 2020 Emre Eran. All rights reserved.
//

import CoreData

public protocol CoreDataObject where Self: NSManagedObject {
    
}

// MARK: - Members
public extension CoreDataObject {
    func delete(context: NSManagedObjectContext) throws {
        context.delete(self)
        try context.save()
    }
}

// MARK: - Helper methods
public extension CoreDataObject {
    static var entity: NSEntityDescription {
        entity()
    }

    static var defaultPredicate: NSPredicate {
        NSPredicate(value: true)
    }

    static var defaultCompoundPredicate: NSCompoundPredicate {
        NSCompoundPredicate(type: .and, subpredicates: [defaultPredicate])
    }

    static var defaultSortDescriptors: [NSSortDescriptor] {
        []
    }

    static var request: NSFetchRequest<Self>? {
        if let entityName = entity.name {
            return NSFetchRequest<Self>(entityName: entityName)
        }
        return nil
    }

    static func managedObjectID(forString idString: String, context: NSManagedObjectContext) throws -> NSManagedObjectID {
        if let idURL = NSURL(string: idString) as URL?,
            let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: idURL) {
            return objectID
        }
        throw CoreDataObjectError.malformedObjectID
    }
}

// MARK: - Fetch methods
public extension CoreDataObject {
    static func findByObjectID(context: NSManagedObjectContext, objectID: String) throws -> NSManagedObject? {
        let id = try managedObjectID(forString: objectID, context: context)
        return context.object(with: id)
    }

    static func find(
        context: NSManagedObjectContext,
        where predicate: NSPredicate = defaultPredicate,
        sort descriptors: [NSSortDescriptor] = defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> [Self] {
        return try _find(context: context, where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
    }

    static func find(
        context: NSManagedObjectContext,
        where predicate: NSCompoundPredicate = defaultCompoundPredicate,
        sort descriptors: [NSSortDescriptor] = defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> [Self] {
        return try _find(context: context, where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
    }

    static func findOne(
        context: NSManagedObjectContext,
        where predicate: NSPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> Self? {
        return try _findOne(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    static func findOne(
        context: NSManagedObjectContext,
        where predicate: NSCompoundPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> Self? {
        return try _findOne(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    static func findOneOrThrow(
        context: NSManagedObjectContext,
        where predicate: NSPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> Self {
        return try _findOneOrThrow(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    static func findOneOrThrow(
        context: NSManagedObjectContext,
        where predicate: NSCompoundPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> Self {
        return try _findOneOrThrow(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    static func delete(context: NSManagedObjectContext, where predicate: NSPredicate) throws {
        if let entityName = entity.name {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = predicate
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            deleteRequest.resultType = .resultTypeObjectIDs

            let result = try context.execute(deleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: result.result as! [NSManagedObjectID]
            ]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            return
        }
        throw CoreDataObjectError.invalidEntity
    }
}

// MARK: - Count methods
public extension CoreDataObject {
    static func count(context: NSManagedObjectContext, where predicate: NSPredicate = defaultPredicate) throws -> Int {
        return try _count(context: context, where: predicate)
    }

    static func count(context: NSManagedObjectContext, where predicate: NSCompoundPredicate = defaultCompoundPredicate) throws -> Int {
        return try _count(context: context, where: predicate)
    }
}

// MARK: - Private Members
extension CoreDataObject {
    private static func _find<P: NSPredicate>(
        context: NSManagedObjectContext,
        where predicate: P,
        sort descriptors: [NSSortDescriptor],
        prefetch relationshipKeyPathsForPrefetching: [String]
    ) throws -> [Self] {
        if let req = request {
            req.predicate = predicate
            req.sortDescriptors = descriptors
            req.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
            return try fetch(context: context, request: req)
        }
        throw CoreDataObjectError.invalidEntity
    }

    private static func _findOne<P: NSPredicate>(
        context: NSManagedObjectContext,
        where predicate: P,
        prefetch relationshipKeyPathsForPrefetching: [String]
    ) throws -> Self? {
        if let req = request {
            req.predicate = predicate
            req.fetchLimit = 2
            req.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
            let result = try fetch(context: context, request: req)
            switch result.count {
            case 0:
                return nil
            case 1:
                return result[0]
            default:
                throw CoreDataObjectError.singleResultExpected(got: result)
            }
        }
        throw CoreDataObjectError.invalidEntity
    }

    private static func _findOneOrThrow<P: NSPredicate>(
        context: NSManagedObjectContext,
        where predicate: P,
        prefetch relationshipKeyPathsForPrefetching: [String]
    ) throws -> Self {
        if let result = try _findOne(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching) {
            return result
        }
        throw CoreDataObjectError.entityNotFound
    }

    private static func _count<P: NSPredicate>(context: NSManagedObjectContext, where predicate: P) throws -> Int {
        if let req = request {
            req.predicate = predicate
            req.includesSubentities = false
            return try context.count(for: req)
        }
        throw CoreDataObjectError.invalidEntity
    }

    private static func fetch(context: NSManagedObjectContext, request: NSFetchRequest<Self>) throws -> [Self] {
        request.returnsObjectsAsFaults = false
        return try context.fetch(request)
    }
}

// MARK: - Error types
enum CoreDataObjectError: Error {
    case invalidEntity
    case malformedObjectID
    case entityNotFound
    case singleResultExpected(got: [NSManagedObject])
    case couldNotGetObjectContext
}
