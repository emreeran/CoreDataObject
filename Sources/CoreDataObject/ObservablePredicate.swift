//
//  ObservablePredicate.swift
//  CoreDataObject
//
//  Created by Emre Eran on 12.03.2020.
//  Copyright © 2020 Emre Eran. All rights reserved.
//

import CoreData

public class ObservablePredicate<T: CoreDataObject>: NSObject {
    typealias DataUpdated = (_: [T]) -> Void
    typealias HasError = (_: Error) -> Void

    var data: [T] = []
    var context: NSManagedObjectContext
    var predicate: NSPredicate
    var descriptors: [NSSortDescriptor]
    var relationshipKeyPathsForPrefetching: [String]
    var notifier: DataUpdated
    var onError: HasError?

    init(
        context: NSManagedObjectContext,
        where predicate: NSPredicate = T.defaultPredicate,
        sort descriptors: [NSSortDescriptor] = T.defaultSortDescriptors,
        prefetch relationshipKeyPathsForPrefetching: [String] = [],
        notifier: @escaping DataUpdated,
        onError: HasError? = nil
    ) {
        self.context = context
        self.predicate = predicate
        self.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
        self.descriptors = descriptors
        self.notifier = notifier
        self.onError = onError
        super.init()

        CoreDataObserver.default.subscribe(to: T.self, observer: self)
        refresh()
    }

    deinit {
        CoreDataObserver.default.unsubscribe(from: T.self, observer: self)
    }

    private func refresh() {
        do {
            let result = try T.find(context: context, where: predicate, sort: descriptors, prefetch: relationshipKeyPathsForPrefetching)
            if result != data {
                data = result
                notifier(result)
            }
        } catch {
            onError?(error)
        }
    }
}

extension ObservablePredicate: CoreDataObjectTypeChangeListener {
    func changed(type: [ContextObjectChangeType]) {
        refresh()
    }
}
