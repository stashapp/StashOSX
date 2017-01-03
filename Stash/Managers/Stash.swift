//
//  Stash.swift
//  Stash
//
//

import Foundation
import FileKit
import SwiftyJSON

class Stash {
    struct Paths {
        static let scenes = Path("~/.stash/scenes", expandingTilde: true)
        static let performers = Path("~/.stash/performers", expandingTilde: true)
        static let mappings = Path("~/.stash/mappings.json", expandingTilde: true)
    }
    
    static func initialize() {
        do {
            if !Paths.scenes.exists { try Paths.scenes.createDirectory() }
            if !Paths.performers.exists { try Paths.performers.createDirectory() }
        } catch { fatalError("Failed to create directories!") }
    }
    
    static func addPerformer(imageUrl url: URL) {
        guard let path = Path(url: url) else { return }
        
        let checksum = path.calculateChecksum()
        let performerPath = Paths.performers + "\(checksum).\(path.pathExtension)"
        
        do {
            try path.copyFile(to: performerPath)
            
            if Database.shared.performer(fromChecksum: checksum) == nil {
                let performer = Performer(context: Database.shared.viewContext)
                performer.checksum = checksum
                performer.name = path.fileName
                Database.shared.saveContext()
            }
        } catch {
            debugPrint("Error adding performer \(error)")
        }
    }
    
    struct Images {
        static func performer(withChecksum checksum: String) -> Image? {
            let path = Paths.performers + "\(checksum).jpg"
            
            do {
                return try ImageFile(path: path).read()
            } catch { return nil }
        }
    }
    
    struct Json {
        static func scene(withChecksum checksum: String) -> JSON? {
            do {
                let file = DataFile(path: Paths.scenes + "\(checksum).json")
                if !file.exists {
                    return nil
                }

                let data = try file.read()
                return JSON(data: data)
            } catch {
                return nil
            }
        }
        
        static func saveScene(checksum: String, json: JSON) {
            do {
                let file = DataFile(path: Paths.scenes + "\(checksum).json")
                createIfNeeded(file)
                try file.write(json.rawData(options: .prettyPrinted), options: .atomic)
                debugPrint("Saved scene json \(checksum).json")
            } catch {
                
            }
        }
        
        static func performer(withChecksum checksum: String) -> JSON? {
            do {
                let file = DataFile(path: Paths.performers + "\(checksum).json")
                if !file.exists {
                    return nil
                }
                
                let data = try file.read()
                return JSON(data: data)
            } catch {
                return nil
            }
        }
        
        static func savePerformer(checksum: String, json: JSON) {
            do {
                let file = DataFile(path: Paths.performers + "\(checksum).json")
                createIfNeeded(file)
                try file.write(json.rawData(options: .prettyPrinted), options: .atomic)
                debugPrint("Saved performer json \(checksum).json")
            } catch {
                
            }
        }
        
        static func mappings() -> JSON? {
            do {
                let file = DataFile(path: Paths.mappings)
                if !file.exists { return nil }
                
                let data = try file.read()
                return JSON(data: data)
            } catch { return nil }
        }
        
        static func saveMappings(json: JSON) {
            do {
                let file = DataFile(path: Paths.mappings)
                createIfNeeded(file)
                try file.write(json.rawData(options: .prettyPrinted), options: .atomic)
                debugPrint("Saved mappings file")
            } catch {
                debugPrint("Error saving mappings file \(error)")
            }
        }
        
        private static func createIfNeeded(_ file: DataFile) {
            do {
                if !file.exists {
                    try file.create()
                    debugPrint("Created json file \(file.name)")
                }
            } catch {
                print("Failed to create file")
            }
        }
    }
}
