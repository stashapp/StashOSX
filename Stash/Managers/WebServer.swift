//
//  WebServer.swift
//  Stash
//
//

import Foundation
import Swifter
import SwiftyJSON
import Groot
import FileKit

class WebServer {
    static let shared = WebServer()
    
    private let server = HttpServer()
    
    static func initialize() {
        do {
            shared.configureRoutes()
            try shared.server.start(4000)
        } catch {
            debugPrint("Failed to start web server!")
        }
    }
    
    private func configureRoutes() {
        server["/"] = { r in
            return .ok(.text("Hello World from Stash!"))
        }
        
        server["/test/:param1/:param2"] = { r in
            return .ok(.text("1: \(r.params[":param1"]), 2: \(r.params[":param2"])"))
        }
        
        
        server["/scene/:checksum"] = { r in
            guard let scene = Database.shared.scene(fromChecksum: r.params[":checksum"] ?? "") else { return .notFound }
            
            let j = JSON(json(fromObject: scene))
            return .ok(.text(j.rawString(.utf8, options: .prettyPrinted) ?? "[]"))
        }
        
        server["/scene/:checksum/image"] = { r in
            guard let scene = Database.shared.scene(fromChecksum: r.params[":checksum"] ?? "") else { return .notFound }
            
            let image = FFMPEG.screenshot(forScene: scene)
            guard var data = image?.tiffRepresentation else { return .internalServerError }
            guard let imageRep = NSBitmapImageRep(data: data) else { return .internalServerError }
            data = imageRep.representation(using: .JPEG, properties: [:]) ?? Data()
            
            return .raw(200, "OK", ["Content-Type": "image/jpeg"], { try $0.write(data) })
        }
        
        server["/scene/:checksum/stream"] = { r in
            guard let scene = Database.shared.scene(fromChecksum: r.params[":checksum"] ?? "") else { return .notFound }
            guard let path = scene.path else { return .internalServerError }
            let file = Path(path)
            
            // TODO: Clean this up and verify it is to spec
            
            var startBytes: UInt64 = 0
            var endBytes: UInt64 = 1024 * 1024 * 30
            for item in r.headers {
                switch item.0 {
                case "range":
                    var bytesString = item.1
                    bytesString = item.1.replacingOccurrences(of: "bytes=", with: "")
                    let arr = bytesString.components(separatedBy: "-")
                    startBytes = UInt64(arr.first ?? "0") ?? 0
                    endBytes = UInt64(arr.last ?? "\(startBytes + UInt64(1024 * 1024 * 30))") ?? (startBytes + UInt64(1024 * 1024 * 30))
                default:
                    break
                }
            }
            
            let fileSize = String(Int(file.fileSize ?? 0))
            guard let f = file.fileHandleForReading else { return .internalServerError }
            f.seek(toFileOffset: startBytes)
            let data = f.readData(ofLength: Int(endBytes - startBytes))
            
            let contentRange = "bytes \(startBytes)-\(endBytes)/\(fileSize)"
            return .raw(206, "OK", ["Content-Type": "video/mp4", "Accept-Ranges": "bytes", "Content-Length": fileSize, "Content-Range": contentRange], { w in
                do {
                    try w.write(data)
                } catch {
                    f.closeFile()
                }
                f.closeFile()
            })
        }
        
        server["/scenes/"] = { [weak self] r in
            guard let this = self else { return .internalServerError }

            let scenes = this.data(Database.shared.scenes(), request: r)
            let j = JSON(json(fromObjects: scenes))
            return .ok(.text(j.rawString(.utf8, options: .prettyPrinted) ?? "[]"))
        }
        
        server["/scenes/html"] = { [weak self] r in
            // TODO: This sucks, improve it later
            guard let this = self else { return .internalServerError }
            let scenes = this.data(Database.shared.scenes(), request: r)
            
            return scopes {
                html {
                    body {
                        table(scenes) { scene in
                            tr {
                                td {
                                    a {
                                        href = "/scene/\(scene.checksum!)/stream"
                                        img {
                                            src = "/scene/\(scene.checksum!)/image"
                                            height = String(50)
                                        }
                                    }
                                }
                                td { inner = scene.path }
                            }
                        }
                    }
                }
            }(r)
        }
    }
    
    private func int(_ string: String) -> Int {
        let value = Int(string) ?? 0
        return value >= 0 ? value : 0
    }
    
    private func data<T: NSManagedObject>(_ all: [T], request: HttpRequest) -> [T] {
        var offset = 0
        var limit  = 100
        for item in request.queryParams {
            switch item.0 {
            case "offset":
                offset = int(item.1)
            case "limit":
                limit = int(item.1)
            default:
                break
            }
        }
        
        guard offset < offset + limit else { return [] }
        guard offset < all.count else { return [] }
        
        let end = offset+limit < all.count ? offset+limit : all.count
        return Array(all[offset ..< end])
    }
}
