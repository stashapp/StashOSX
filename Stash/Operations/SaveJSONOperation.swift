//
//  SaveJSONOperation.swift
//  Stash
//
//

import Foundation
import SwiftyJSON

class SaveJSONOperation: Operation {
    override func main() {
        do {
            let scenes: [Scene] = try Database.shared.viewContext.fetch(Scene.fetchRequest())
            let performers: [Performer] = try Database.shared.viewContext.fetch(Performer.fetchRequest())
            
            var sceneMappings: [JSON] = []
            for scene in scenes {
                guard let checksum = scene.checksum else { continue }
                
                // Save checksums for the mapping file
                if let path = scene.path {
                    sceneMappings.append(JSON(["path": path, "checksum": checksum]))
                }
                
                let fileJSON = Stash.Json.performer(withChecksum: checksum)
                var json = JSON([:])
                
                if scene.title != nil        { json["title"].string  = scene.title }
                if scene.studio?.name != nil { json["studio"].string = scene.studio?.name }
                if scene.url != nil          { json["url"].string = scene.url }
                if scene.details != nil      { json["details"].string = scene.details }
                
                let performerNames: [String] = scene.performers?.flatMap({ performer in
                    guard let performer = performer as? Performer else { return nil }
                    return performer.name
                }).sorted() ?? []
                if !performerNames.isEmpty { json["performers"].arrayObject = performerNames }
                
                let tagNames: [String] = scene.tags?.flatMap({ tag in
                    guard let tag = tag as? Tag else { return nil }
                    return tag.name
                }).sorted() ?? []
                if !tagNames.isEmpty { json["tags"].arrayObject = tagNames }
                
                if json.isEmpty { continue }
                if fileJSON == json { continue }
                
                Stash.Json.saveScene(checksum: checksum, json: json)
            }
            
            // Performers
            
            var performerMappings: [JSON] = []
            for performer in performers {
                guard let checksum = performer.checksum else { continue }
                
                // Save checksums for the mapping file
                if let name = performer.name {
                    performerMappings.append(JSON(["name": name, "checksum": checksum]))
                }
                
                let fileJSON = Stash.Json.performer(withChecksum: checksum)
                var json = JSON([:])
                
                if performer.name != nil { json["name"].string = performer.name }
                
                if json.isEmpty { continue }
                if fileJSON == json { continue }
                
                Stash.Json.savePerformer(checksum: checksum, json: json)
            }
            
            let mappingsJSON = JSON(["performers": JSON(performerMappings), "scenes": JSON(sceneMappings)])
            Stash.Json.saveMappings(json: mappingsJSON)
            
            debugPrint("Save complete!")
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
