//
//  FileTreeNode.swift
//  Stash
//
//

import Cocoa
import FileKit
import SwiftyJSON

class FileTreeNode: NSObject {
    private let path: Path
    private var scene: Scene? = nil
    
    init(_ path: Path) {
        self.path = path
        
        if path.isRegular {
            self.scene = Database.shared.scene(fromPath: path)
        }
        
        super.init()
    }
    
    var isLeaf: Bool {
        get {
            return path.isRegular
        }
    }
    
    var children: [FileTreeNode]? {
        get {
            var childNodes: [FileTreeNode] = []
            for childPath in path.children() {
                if Database.shared.isValidPath(path: childPath) || childPath.isDirectory {
                    let node = FileTreeNode(childPath)
                    childNodes.append(node)
                }
            }
            
            return childNodes
        }
    }
    
    var fileName: String {
        get {
            return path.fileName
        }
    }
    
    var fileHash: String? {
        get {
            return scene?.checksum
        }
    }
    
    var title: String? {
        get {
            return scene?.title
        }
        set {
            scene?.title = newValue
            Database.shared.saveContext()
        }
    }
    
    var url: String? {
        get {
            return scene?.url
        }
        set {
            scene?.url = newValue
            Database.shared.saveContext()
        }
    }
    
    var studio: String? {
        get {
            return scene?.studio?.name
        }
        set {
            guard let studioName = newValue else {
                scene?.studio = nil
                Database.shared.saveContext()
                return
            }
            let studio = Database.shared.studio(withName: studioName) ?? Studio(context: Database.shared.viewContext)
            studio.name = studioName
            scene?.studio = studio
            Database.shared.saveContext()
        }
    }
    
    var gallery: String? {
        get {
            return nil
        }
        set {
            
        }
    }
    
    var performers: [String]? {
        get {
            guard let scenePerformers = scene?.performers else { return nil }
            var performers: [String] = []
            for performer in scenePerformers {
                guard let p = performer as? Performer else { continue }
                guard let name = p.name else { continue }
                performers.append(name)
            }
            
            return performers
        }
        set {
            guard let performerNames = newValue else { return }
            
            var performers: [Performer] = []
            for performerName in performerNames {
                if let performer = Database.shared.performer(withName: performerName) {
                    performers.append(performer)
                }
            }
            
            scene?.performers = NSSet(array: performers)
            Database.shared.saveContext()
        }
    }
    
    var tags: [String]? {
        get {
            guard let sceneTags = scene?.tags else { return nil }
            var tags: [String] = []
            for tag in sceneTags {
                guard let t = tag as? Tag else { continue }
                guard let name = t.name else { continue }
                tags.append(name)
            }
            
            return tags
        }
        set {
            guard let tagNames = newValue else { return }
            
            var tags: [Tag] = []
            for tagName in tagNames {
                let tag = Database.shared.tag(withName: tagName) ?? Tag(context: Database.shared.viewContext)
                tag.name = tagName
                tags.append(tag)
            }
            
            scene?.tags = NSSet(array: tags)
            Database.shared.saveContext()
        }
    }
    
    var details: String? {
        get {
            return scene?.details
        }
        set {
            scene?.details = newValue
            Database.shared.saveContext()
        }
    }
}
