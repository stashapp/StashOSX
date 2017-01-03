//
//  ImportJSONOperation.swift
//  Stash
//
//

import Foundation
import SwiftyJSON

class ImportJSONOperation: Operation {
    override func main() {
        guard let mappingsJSON = Stash.Json.mappings() else { return }
        
        for performerJSON in mappingsJSON["performers"].arrayValue {
            let performer = Performer(context: Database.shared.viewContext)
            performer.checksum = performerJSON["checksum"].stringValue
            performer.name     = performerJSON["name"].stringValue
            
            debugPrint("Imported performer \(performer.name)")
        }
        
        for fileJSON in mappingsJSON["scenes"].arrayValue {
            let scene = Scene(context: Database.shared.viewContext)
            scene.checksum = fileJSON["checksum"].stringValue
            scene.path     = fileJSON["path"].stringValue
            
            guard let json = Stash.Json.scene(withChecksum: fileJSON["checksum"].stringValue) else { continue }
            
            scene.title      = json["title"].string
            scene.details    = json["details"].string
            scene.url        = json["url"].string
            
            if let studioName = json["studio"].string {
                if let studio = Database.shared.studio(withName: studioName) {
                    scene.studio = studio
                } else {
                    debugPrint("Created new studio named \(studioName)")
                    // TODO: Export a studio JSON file and read from that here.
                    scene.studio = Studio(context: Database.shared.viewContext)
                    scene.studio?.name = studioName
                }
            }
            
            let performers: [Performer] = json["performers"].arrayValue.flatMap({ performerName in
                if let performer = Database.shared.performer(withName: performerName.stringValue) {
                    return performer
                } else {
                    debugPrint("ERROR: Performer does not exist! \(performerName.stringValue)")
                    return nil
                }
            })
            if !performers.isEmpty {
                scene.addToPerformers(NSSet(array: performers))
            }
            
            let tags: [Tag] = json["tags"].arrayValue.flatMap({ tagName in
                if let tag = Database.shared.tag(withName: tagName.stringValue) {
                    return tag
                } else {
                    debugPrint("Created new tag named \(tagName.stringValue)")
                    // TODO: Export a tags JSON file and read from that here.
                    let tag = Tag(context: Database.shared.viewContext)
                    tag.name = tagName.stringValue
                    return tag
                }
            })
            if !tags.isEmpty {
                scene.addToTags(NSSet(array: tags))
            }
            
            debugPrint("Imported scene \(fileJSON["path"].stringValue)")
        }
        
        Database.shared.saveContext()
    
        debugPrint("Import complete!")
    }
}
