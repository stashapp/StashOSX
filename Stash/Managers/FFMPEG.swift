//
//  FFMPEG.swift
//  Stash
//
//

import Foundation
import FileKit
import SwiftyJSON

struct FFProbeInformation {
    let duration: Double
    let width: Int
    let height: Int
}

class FFMPEG {
    static let ffmpegPath = Path("~/.stash/bin/ffmpeg", expandingTilde: true)
    static let ffprobePath = Path("~/.stash/bin/ffprobe", expandingTilde: true)
    static let screenshotsPath = Path("~/.stash/screenshots", expandingTilde: true)
    
    static func initialize() {
        if !screenshotsPath.exists {
            do {
                try screenshotsPath.createDirectory()
            } catch {
                assertionFailure("Failed to create screenshots directory!")
            }
        }
        
        guard !ffmpegPath.exists && !ffprobePath.exists else { return }
        
        debugPrint("FFMPEG not found!")
        
        let alert = NSAlert()
        alert.messageText = "FFMPEG not found!  Install it to ~/.stash/bin and retry."
        alert.addButton(withTitle: "Retry")
        alert.addButton(withTitle: "Quit")
        let result = alert.runModal()
        
        switch(result) {
        case NSAlertFirstButtonReturn:
            initialize()
        case NSAlertSecondButtonReturn:
            NSApp.terminate(self)
        default:
            break
        }
    }
    
    static func makeScreenshots(forScene scene: Scene, force: Bool = false) {
        guard let path = scene.path, let checksum = scene.checksum else { return }
        let thumbPath = screenshotsPath + "\(checksum).thumb.jpg"
        let largePath = screenshotsPath + "\(checksum).jpg"
        if thumbPath.exists && largePath.exists && !force { return }
        
        let videoPath = Path(path)
        let probeInfo = probe(videoPath: videoPath)
        let time = probeInfo.duration * 0.2
        
        let thumbData = screenshot(videoPath: videoPath, time: Int(time), quality: 5, width: 320)
        let largeData = screenshot(videoPath: videoPath, time: Int(time), quality: 2, width: probeInfo.width)
        
        if thumbData.isEmpty && largeData.isEmpty { return }
        
        do {
            try thumbData.write(to: thumbPath)
            try largeData.write(to: largePath)
            debugPrint("Wrote screenshots for \(checksum)")
        } catch {
            debugPrint("Failed to write screenshots for scene \(scene), \(error)")
        }
    }
    
    static func screenshot(forScene scene: Scene, thumb: Bool = false) -> Image? {
        guard let checksum = scene.checksum else { return nil }
        let thumbPath = screenshotsPath + "\(checksum).thumb.jpg"
        let largePath = screenshotsPath + "\(checksum).jpg"
        
        do {
            if thumb {
                return try ImageFile(path: thumbPath).read()
            } else {
                return try ImageFile(path: largePath).read()
            }
        } catch {
            return nil
        }
    }
    
    static func screenshot(videoPath: Path, time: Int = 20, quality: Int = 2, width: Int = 1280) -> Data {
        let process = Process()
        process.launchPath = ffmpegPath.standardRawValue
        process.arguments = ["-v", "quiet", "-ss", "\(time)", "-i", videoPath.standardRawValue, "-vframes", "1", "-q:v", "\(quality)", "-vf", "scale='\(width):-1'", "-f", "image2pipe", "pipe:1"]
        process.qualityOfService = .utility
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        return pipe.fileHandleForReading.readDataToEndOfFile()
    }
    
    static func probe(videoPath: Path) -> FFProbeInformation {
        let process = Process()
        process.launchPath = ffprobePath.standardRawValue
        process.arguments = ["-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", videoPath.standardRawValue]
        process.qualityOfService = .utility
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        let json = JSON(data: data)
        let stream = json["streams"].arrayValue.first
        let duration = json["format"]["duration"].doubleValue
        let width    = stream?["width"].int ?? 640
        let height   = stream?["height"].int ?? 480
        let probeInfo = FFProbeInformation(duration: duration, width: width, height: height)
        
        return probeInfo
    }
}
