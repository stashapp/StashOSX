//
//  ScanOperation.swift
//  Stash
//
//

import Foundation
import FileKit
import IDZSwiftCommonCrypto

class ScanOperation: Operation {
    let path: Path
    let progress: Progress
    
    init(path: Path, progress: Progress) {
        self.path = path
        self.progress = progress
    }
    
    override func main() {
        let files = Database.shared.vaildFilePaths(forPath: path)
        progress.totalUnitCount = Int64(files.count)
        
        scan(files: files)
        
        updateMessage("Done!")
    }
    
    private func scan(files: [Path]) {
        guard !isCancelled else { return }
        
        for filePath in files {
            updateMessage("Starting scan of \(filePath.standardRawValue)")
            
            if Database.shared.isVideo(filePath) {
                var scene = Database.shared.scene(fromPath: filePath)
                
                if scene == nil {
                    let checksum = calculateChecksum(path: filePath)
                    scene = Database.shared.scene(fromChecksum: checksum)
                    
                    if scene == nil {
                        scene = Scene(context: Database.shared.viewContext)
                        scene?.checksum = checksum
                    }
                    
                    scene?.path = filePath.standardRawValue
                    Database.shared.saveContext()
                }
                
                if let scene = scene {
                    updateMessage("Making screenshots for \(filePath.standardRawValue)")
                    FFMPEG.makeScreenshots(forScene: scene)
                }
            } else {
                // TODO: Handle ZIP
            }
            
            progress.completedUnitCount += 1
        }
    }
    
    private func calculateChecksum(path: Path) -> String {
        updateMessage("Calculating checksum for \(path.standardRawValue)")
        return path.calculateChecksum()
    }
    
    private func updateMessage(_ message: String) {
        let count = progress.completedUnitCount + 1 > progress.totalUnitCount ? progress.totalUnitCount : progress.completedUnitCount + 1
        let log = "File \(count) of \(progress.totalUnitCount)\n\n\(message)"
//        debugPrint(log)
        progress.localizedAdditionalDescription = log
    }
}
