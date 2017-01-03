//
//  DatabaseManager.swift
//  Stash
//
//

import Foundation
import FileKit
import IDZSwiftCommonCrypto

class Database {
    
    static let queue: OperationQueue = {
        let q = OperationQueue()
        q.qualityOfService = .utility
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    static func scan(path: Path, progress: Progress) -> ScanOperation {
        let operation = ScanOperation(path: path, progress: progress)
        operation.completionBlock = {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshCompleted"), object: nil)
            }
        }
        queue.addOperation(operation)
        
        return operation
    }
    
    
    
    
    static let shared = Database()
    var errorHandler: (Error) -> Void = {_ in }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "StashModel")
        container.loadPersistentStores(completionHandler: { [weak self] storeDescription, error in
            if let error = error as NSError? {
                debugPrint("CoreData error \(error), \(error.userInfo)")
                self?.errorHandler(error)
            }
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        })
        return container
    }()
    
    lazy var viewContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    func performForegroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        viewContext.perform {
            block(self.viewContext)
        }
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        self.persistentContainer.performBackgroundTask(block)
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch let error as NSError {
                if error.code == NSFileReadUnknownError {
                    print("Wut!? \(error.userInfo)\n\n")
                } else {
                    fatalError("Unable to save view context \(error), \(error.userInfo)")
                }
            }
        }
    }
    
    
    
    
    func vaildFilePaths(forPath path: Path) -> [Path] {
        return path.find(condition: { path in
            return isValidPath(path: path)
        })
    }
    
    func isValidPath(path: Path) -> Bool {
        return isVideo(path) || isGallery(path)
    }
    
    func isVideo(_ path: Path) -> Bool {
        return path.pathExtension == "mp4" || path.pathExtension == "mov" || path.pathExtension == "wmv"
    }
    
    func isGallery(_ path: Path) -> Bool {
        return path.pathExtension == "zip"
    }
    
    
    
    func isDatabaseEmpty() -> Bool {
        do {
            return try backgroundContext.count(for: Scene.fetchRequest()) == 0
        } catch {
            return true
        }
    }
    
    
    
    
    
    
    
    func studios(startingWith substring: String) -> [Studio] {
        return items(startingWith: substring, type: Studio.self)
    }
    
    func studios() -> [Studio] {
        return items(type: Studio.self)
    }
    
    func tags(startingWith substring: String) -> [Tag] {
        return items(startingWith: substring, type: Tag.self)
    }
    
    func tagsAsStrings(startingWith substring: String) -> [String] {
        let tags = items(startingWith: substring, type: Tag.self)
        
        var tagNames: [String] = []
        for tag in tags {
            guard let name = tag.name else { continue }
            tagNames.append(name)
        }
        
        return tagNames
    }
    
    func performers() -> [Performer] {
        return items(type: Performer.self)
    }
    
    func performers(startingWith substring: String) -> [Performer] {
        return items(startingWith: substring, type: Performer.self)
    }
    
    func performersAsStrings(startingWith substring: String) -> [String] {
        let performers = items(startingWith: substring, type: Performer.self)
        
        var performerNames: [String] = []
        for performer in performers {
            guard let name = performer.name else { continue }
            performerNames.append(name)
        }
        
        return performerNames
    }
    
    
    
    
    func scene(fromPath path: Path) -> Scene? {
        return item(predicate: NSPredicate(format: "path == %@", path.standardRawValue), type: Scene.self)
    }
    
    func scene(fromChecksum checksum: String) -> Scene? {
        return item(predicate: NSPredicate(format: "checksum == %@", checksum), type: Scene.self)
    }
    
    func scenes(fromPredicate predicate: NSPredicate? = nil) -> [Scene] {
        return items(predicate: predicate, type: Scene.self)
    }
    
    func studio(withName name: String) -> Studio? {
        return item(predicate: NSPredicate(format: "name == %@", name), type: Studio.self)
    }
    
    func tag(withName name: String) -> Tag? {
        return item(predicate: NSPredicate(format: "name == %@", name), type: Tag.self)
    }
    
    func performer(withName name: String) -> Performer? {
        return item(predicate: NSPredicate(format: "name == %@", name), type: Performer.self)
    }
    
    func performer(fromChecksum checksum: String) -> Performer? {
        return item(predicate: NSPredicate(format: "checksum == %@", checksum), type: Performer.self)
    }
    
    private func items<T: NSManagedObject>(predicate: NSPredicate? = nil, type: T.Type) -> [T] {
        do {
            let request = T.fetchRequest()
            if let predicate = predicate {
                request.predicate = predicate
            }
            return try viewContext.fetch(request) as! [T]
        } catch {
            debugPrint(error.localizedDescription)
            return []
        }
    }
    
    private func items<T: NSManagedObject>(startingWith substring: String, type: T.Type) -> [T] {
        var predicate: NSPredicate? = nil
        if !substring.isEmpty {
            predicate = NSPredicate(format: "name BEGINSWITH[c] '\(substring)'")
        }
        
        return items(predicate: predicate, type: type)
    }
    
    private func item<T: NSManagedObject>(predicate: NSPredicate, type: T.Type, context: NSManagedObjectContext? = nil) -> T? {
        do {
            let ctx = context ?? viewContext
            let request = T.fetchRequest()
            request.predicate = predicate
            request.fetchLimit = 100
            if let item = try ctx.fetch(request).first as? T {
                return item
            } else {
                return nil
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
