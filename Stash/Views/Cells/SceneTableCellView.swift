//
//  SceneTableCellView.swift
//  Stash
//
//

import Cocoa

class SceneTableCellView: NSTableCellView {
    @IBOutlet weak var checksumLabel: NSTextField!
    @IBOutlet weak var pathLabel: NSTextField!
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var studioLabel: NSTextField!
    @IBOutlet weak var detailsLabel: NSTextField!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView?.image = nil
        checksumLabel.objectValue = nil
        pathLabel.objectValue = nil
        titleLabel.objectValue = nil
        studioLabel.objectValue = nil
        detailsLabel.objectValue = nil
    }
    
    func configure(_ scene: Scene) {
        imageView?.image = FFMPEG.screenshot(forScene: scene, thumb: true)
        checksumLabel.objectValue = scene.checksum
        pathLabel.objectValue = scene.path
        titleLabel.objectValue = scene.title
        studioLabel.objectValue = scene.studio?.name
        detailsLabel.objectValue = scene.details
    }
}
