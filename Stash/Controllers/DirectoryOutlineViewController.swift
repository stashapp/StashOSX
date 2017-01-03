//
//  DirectoryOutlineViewController.swift
//  Stash
//
//

import Cocoa

protocol DirectoryOutlineViewControllerDelegate {
    func outlineViewSelectionDidChange()
}

class DirectoryOutlineViewController: NSViewController, NSOutlineViewDelegate {
    var delegate: DirectoryOutlineViewControllerDelegate?
    
    @IBOutlet weak var directoryOutlineView: NSOutlineView!
    @IBOutlet weak var folderTableColumn: NSTableColumn!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = NSApp.delegate as! AppDelegate
        let treeController = appDelegate.directoryTreeController
        
        directoryOutlineView.selectionHighlightStyle = .sourceList
        
//        directoryOutlineView.exposedBindings
        directoryOutlineView.bind("content", to: treeController, withKeyPath: "arrangedObjects")
        directoryOutlineView.bind("selectionIndexPaths", to: treeController, withKeyPath: "selectionIndexPaths")
        folderTableColumn.bind("value", to: treeController, withKeyPath: "arrangedObjects.fileName")
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let delegate = delegate else { return }
        delegate.outlineViewSelectionDidChange()
//        directoryOutlineView.expandItem(directoryOutlineView.item(atRow: 0))
    }
}
