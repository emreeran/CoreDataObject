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
    var context: NSManagedObjectContext? { get set }
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

    func save<M: Any>(items: [M], map: ((_: M, _: T) -> Void)) throws {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        for item in items {
            if let object = NSManagedObject.init(entity: T.entity(), insertInto: context) as? T {
                map(item, object)
            }
        }
        try context.save()
    }

    func list(
        where predicate: NSPredicate = T.defaultPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> [T] {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.find(context: context, where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
    }

    func findOne(where predicate: NSPredicate, prefetch relationshipKeyPathsForPrefetching: [String] = []) throws -> T? {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.findOne(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    func findOneOrThrow(where predicate: NSPredicate, prefetch relationshipKeyPathsForPrefetching: [String] = []) throws -> T {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.findOneOrThrow(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    func delete(_ object: T) throws {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        try object.delete(context: context)
    }

    func delete(where predicate: NSPredicate) throws {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        try T.delete(context: context, where: predicate)
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
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping (([T]) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservablePredicate<T, NSPredicate> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservablePredicate<T, NSPredicate>(
            context: context,
            where: predicate,
            sort: descriptors,
            prefetch: relationshipKeyPathsForPrefetching,
            notifier: notifier,
            onError: onError
        )
    }

    func findObservable(
        where predicate: NSCompoundPredicate = T.defaultCompoundPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping (([T]) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservablePredicate<T, NSCompoundPredicate> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservablePredicate<T, NSCompoundPredicate>(
            context: context,
            where: predicate,
            sort: descriptors,
            prefetch: relationshipKeyPathsForPrefetching,
            notifier: notifier,
            onError: onError
        )
    }

    func findOneObservable(
        where predicate: NSPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping ((T?) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservableCoreDataObject<T, NSPredicate> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservableCoreDataObject(context: context, predicate: predicate, notifier: notifier, onError: onError)
    }

    func findOneObservable(
        where predicate: NSCompoundPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping ((T?) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservableCoreDataObject<T, NSCompoundPredicate> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservableCoreDataObject(context: context, predicate: predicate, notifier: notifier, onError: onError)
    }
}
