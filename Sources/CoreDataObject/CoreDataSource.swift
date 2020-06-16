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

    // MARK: - List Methods
    func list(
        where predicate: NSPredicate = T.defaultPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> [T] {
        return try _list(where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
    }

    func list(
        where predicate: NSCompoundPredicate = T.defaultCompoundPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> [T] {
        try _list(where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
    }

    // MARK: - Find One Methods
    func findOne(where predicate: NSPredicate, prefetch relationshipKeyPathsForPrefetching: [String] = []) throws -> T? {
        try _findOne(where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    func findOne(where predicate: NSCompoundPredicate, prefetch relationshipKeyPathsForPrefetching: [String] = []) throws -> T? {
        try _findOne(where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    func findOneOrThrow(where predicate: NSPredicate, prefetch relationshipKeyPathsForPrefetching: [String] = []) throws -> T {
        try _findOneOrThrow(where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    func findOneOrThrow(where predicate: NSCompoundPredicate, prefetch relationshipKeyPathsForPrefetching: [String] = []) throws -> T {
        try _findOneOrThrow(where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    // MARK: - Delete Methods
    func delete(_ object: T) throws {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        try object.delete(context: context)
    }

    func delete(where predicate: NSPredicate) throws {
        try _delete(where: predicate)
    }

    func delete(where predicate: NSCompoundPredicate) throws {
        try _delete(where: predicate)
    }

    // MARK: - Count Methods
    func count(where predicate: NSPredicate) throws -> Int {
        try _count(where: predicate)
    }

    func count(where predicate: NSCompoundPredicate) throws -> Int {
        try _count(where: predicate)
    }
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
        try _findObservable(where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching, notifier: notifier, onError: onError)
    }

    func findObservable(
        where predicate: NSCompoundPredicate = T.defaultCompoundPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping (([T]) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservablePredicate<T, NSCompoundPredicate> {
        try _findObservable(where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching, notifier: notifier, onError: onError)
    }

    func findOneObservable(
        where predicate: NSPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping ((T?) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservableCoreDataObject<T, NSPredicate> {
        try _findOneObservable(where: predicate, prefetch: relationshipKeyPathsForPrefetching, notifier: notifier, onError: onError)
    }

    func findOneObservable(
        where predicate: NSCompoundPredicate,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping ((T?) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservableCoreDataObject<T, NSCompoundPredicate> {
        try _findOneObservable(where: predicate, prefetch: relationshipKeyPathsForPrefetching, notifier: notifier, onError: onError)
    }
}

// MARK: - Private Members
extension CoreDataSource {
    private func _list<P: NSPredicate>(
        where predicate: P,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = []
    ) throws -> [T] {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.find(context: context, where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
    }

    private func _findOne<P: NSPredicate>(where predicate: P, prefetch relationshipKeyPathsForPrefetching: [String]) throws -> T? {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.findOne(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    private func _findOneOrThrow<P: NSPredicate>(where predicate: P, prefetch relationshipKeyPathsForPrefetching: [String]) throws -> T {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return try T.findOneOrThrow(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    private func _findObservable<P: NSPredicate>(
        where predicate: P,
        sort descriptors: [NSSortDescriptor],
        prefetch relationshipKeyPathsForPrefetching: [String],
        notifier: @escaping (([T]) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservablePredicate<T, P> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservablePredicate<T, P>(
            context: context,
            where: predicate,
            sort: descriptors,
            prefetch: relationshipKeyPathsForPrefetching,
            notifier: notifier,
            onError: onError
        )
    }

    private func _findOneObservable<P: NSPredicate>(
        where predicate: P,
        prefetch relationshipKeyPathsForPrefetching: [String],
        notifier: @escaping ((T?) -> Void),
        onError: ((Error) -> Void)? = nil
    ) throws -> ObservableCoreDataObject<T, P> {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        return ObservableCoreDataObject(context: context, predicate: predicate, notifier: notifier, onError: onError)
    }

    private func _delete<P: NSPredicate>(where predicate: P) throws {
        guard let context = context else {
            throw CoreDataSourceError.couldNotGetObjectContext
        }
        try T.delete(context: context, where: predicate)
    }

    private func _count<P: NSPredicate>(where predicate: P) throws -> Int {
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
