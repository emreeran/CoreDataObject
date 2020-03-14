//
//  DataSource.swift
//  CoreDataSample
//
//  Created by Emre Eran on 10.03.2020.
//  Copyright © 2020 Emre Eran. All rights reserved.
//

import CoreData

public protocol CoreDataSource {
    associatedtype T: CoreDataObject
    var context: NSManagedObjectContext? { get }
}

public extension CoreDataSource {
    typealias initialize = (_: NSManagedObjectContext) -> T

    func new(initialize: initialize) throws -> T {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        let object = initialize(context)
        return try save(object)
    }

    func save<T: NSManagedObject>(_ object: T) throws -> T {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try object.save(context: context) as T
    }

    func list(where predicate: NSPredicate = T.defaultPredicate, sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors) throws -> [T] {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.find(context: context, where: predicate, sort: descriptors)
    }

    func findOne(where predicate: NSPredicate) throws -> T? {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.findOne(context: context, where: predicate)
    }

    func findOneOrThrow(where predicate: NSPredicate) throws -> T {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.findOneOrThrow(context: context, where: predicate)
    }

    func delete(_ object: T) throws {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        try object.delete(context: context)
    }

    func count(where predicate: NSPredicate) throws -> Int {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.count(context: context, where: predicate)
    }
}

enum CoreDataSourceError: Error {
    case couldNotGetObjectContext
    case malformedObjectID
}

// MARK: - Observable queries
public extension CoreDataSource {
    func findObservable(
        where predicate: NSPredicate = T.defaultPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        notifier: @escaping (([T]) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservablePredicate<T> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservablePredicate<T>(context: context, where: predicate, sort: descriptors, notifier: notifier, onError: onError)
    }

    func findOneObservable(where predicate: NSPredicate,  notifier: @escaping ((T?) -> Void), onError: ((Error) -> Void)? = nil) throws -> ObservableCoreDataObject<T> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservableCoreDataObject(context: context, predicate: predicate, notifier: notifier, onError: onError)
    }
}
