//
//  CoreDataObserver.swift
//  CoreDataObject
//
//  Created by Emre Eran on 14.03.2020.
//  Copyright © 2020 Emre Eran. All rights reserved.
//

import CoreData

class CoreDataObserver: NSObject {
    typealias UpdateTypeDict = [String: [ContextObjectChangeType]]

    static let `default`: CoreDataObserver = CoreDataObserver()

    var objectObservers = [NSManagedObjectID: [CoreDataObjectChangeListener]]()
    var typeObservers = [String: [CoreDataObjectTypeChangeListener]]()

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextObjectDidChange(_:)),
            name: Notification.Name.NSManagedObjectContextObjectsDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func subscribe(to id: NSManagedObjectID, observer: CoreDataObjectChangeListener) {
        if objectObservers[id] == nil {
            objectObservers[id] = [CoreDataObjectChangeListener]()
        }
        objectObservers[id]!.append(observer)
    }

    func subscribe<T: CoreDataObject>(to type: T.Type, observer: CoreDataObjectTypeChangeListener) {
        if let key = type.entity.name {
            if typeObservers[key] == nil {
                typeObservers[key] = [CoreDataObjectTypeChangeListener]()
            }
            typeObservers[key]!.append(observer)
        }
    }

    func unsubscribe(from id: NSManagedObjectID, observer: CoreDataObjectChangeListener) {
        if var observers = objectObservers[id] {
            observers.removeAll { $0 == observer }
            if observers.count == 0 {
                objectObservers.removeValue(forKey: id)
            } else {
                objectObservers[id] = observers
            }
        }
    }

    func unsubscribe<T: CoreDataObject>(from type: T.Type, observer: CoreDataObjectTypeChangeListener) {
        if let key = type.entity.name {
            if var observers = typeObservers[key] {
                observers.removeAll { $0 == observer }
                if observers.count == 0 {
                    typeObservers.removeValue(forKey: key)
                } else {
                    typeObservers[key] = observers
                }
            }
        }
    }

    @objc
    private func contextObjectDidChange(_ notification: Notification) {
        guard let info = notification.userInfo else {
            return
        }

        var updatedTypes = map(info: info, type: .inserted)
        updatedTypes = mergeDictionaries(updatedTypes, map(info: info, type: .updated))
        updatedTypes = mergeDictionaries(updatedTypes, map(info: info, type: .deleted))
        updatedTypes = mergeDictionaries(updatedTypes, map(info: info, type: .refreshed))
        updatedTypes = mergeDictionaries(updatedTypes, map(info: info, type: .invalidated))

        for item in updatedTypes {
            if let observers = typeObservers[item.key] {
                for observer in observers {
                    observer.changed(type: item.value)
                }
            }
        }
    }

    private func map(info: [AnyHashable: Any], type: ContextObjectChangeType) -> UpdateTypeDict {
        let objectSet = info[type.key] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        var updatedTypes = UpdateTypeDict()

        for object in objectSet {
            if let observers = objectObservers[object.objectID] {
                for observer in observers {
                    observer.changed(type: type)
                }
            }

            if let key = object.entity.name {
                var updates = updatedTypes[key]
                if updates == nil {
                    updates = [ContextObjectChangeType]()
                }
                if !updates!.contains(type) {
                    updates!.append(type)
                }
                 updatedTypes[key] = updates
            }
        }

        return updatedTypes
    }

    private func mergeDictionaries(_ dict1: UpdateTypeDict, _ dict2: UpdateTypeDict) -> UpdateTypeDict {
        var result = dict1
        result.merge(dict2) { (types1, types2) -> [ContextObjectChangeType] in
            var result = types1
            result.append(contentsOf: types2)
            return result
        }
        return result
    }
}

enum ContextObjectChangeType: String {
    case inserted
    case updated
    case deleted
    case refreshed
    case invalidated

    var key: String {
        switch self {
        case .inserted:
            return NSInsertedObjectsKey
        case .updated:
            return NSUpdatedObjectsKey
        case .deleted:
            return NSDeletedObjectsKey
        case .refreshed:
            return NSRefreshedObjectsKey
        case .invalidated:
            return NSInvalidatedObjectsKey
        }
    }
}

protocol CoreDataObjectChangeListener where Self: NSObject {
    func changed(type: ContextObjectChangeType)
}

protocol CoreDataObjectTypeChangeListener where Self: NSObject {
    func changed(type: [ContextObjectChangeType])
}
