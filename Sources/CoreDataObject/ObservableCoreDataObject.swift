//
//  ObservableCoreDataObject.swift
//  CoreDataObject
//
//  Created by Emre Eran on 13.03.2020.
//  Copyright © 2020 Emre Eran. All rights reserved.
//

import CoreData

public class ObservableCoreDataObject<T: CoreDataObject, P: NSPredicate>: NSObject {
    typealias DataUpdated = (_: T?) -> Void
    typealias HasError = (_: Error) -> Void

    var data: T? = nil
    var objectID: NSManagedObjectID? = nil
    var context: NSManagedObjectContext
    var relationshipKeyPathsForPrefetching: [String]
    var notifier: DataUpdated
    var onError: HasError?

    init(
        context: NSManagedObjectContext,
        predicate: P,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping DataUpdated,
        onError: HasError? = nil
    ) {
        self.onError = onError
        self.context = context
        self.notifier = notifier
        self.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
        super.init()

        fetch(where: predicate, prefetch: relationshipKeyPathsForPrefetching)
    }

    deinit {
        if let objectID = objectID {
            CoreDataObserver.default.unsubscribe(from: objectID, observer: self)
        }
    }

    private func fetch(where predicate: P, prefetch relationshipKeyPathsForPrefetching: [String] = []) {
        do {
            if let result = try T.findOne(context: context, where: predicate, prefetch: relationshipKeyPathsForPrefetching) {
                objectID = result.objectID
                CoreDataObserver.default.subscribe(to: objectID!, observer: self)
                notifier(result)
            }
        } catch {
            onError?(error)
        }
    }

    private func refresh() {
        do {
            // TODO: should get from predicate to apply prefetch
            if let id = objectID?.string {
                let result = try T.findByObjectID(context: context, objectID: id) as? T
                notifier(result)
            }
        } catch {
            onError?(error)
        }
    }
}

extension ObservableCoreDataObject: CoreDataObjectChangeListener {
    func changed(type: ContextObjectChangeType) {
        refresh()
    }
}
