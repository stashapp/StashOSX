//
//  MainContainerViewController.swift
//  Stash
//
//

import Cocoa

class MainContainerViewController: NSSplitViewController, DirectoryOutlineViewControllerDelegate {
    
    var directoryOutlineViewController: DirectoryOutlineViewController!
    var editMetadataViewController: EditMetadataViewController!
    var searchViewController: SearchViewController!
    var performersViewController: PerformersViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        directoryOutlineViewController = storyboard?.instantiateController(withIdentifier: "DirectoryOutlineViewController") as! DirectoryOutlineViewController!
        directoryOutlineViewController.delegate = self
        
        editMetadataViewController = storyboard?.instantiateController(withIdentifier: "EditMetadataViewController") as! EditMetadataViewController
        searchViewController = storyboard?.instantiateController(withIdentifier: "SearchViewController") as! SearchViewController
        performersViewController = PerformersViewController()
        
        displaySearch()
    }
    
    func outlineViewSelectionDidChange() {
        let appDelegate = NSApp.delegate as! AppDelegate
        let directoryTreeController = appDelegate.directoryTreeController
        guard editMetadataViewController != nil else { return }
        guard let fileNode = directoryTreeController.selectedObjects.first as? FileTreeNode else { return }
//        editMetadataViewController.view.isHidden = !fileNode.isLeaf
        
        if fileNode.isLeaf {
            if splitViewItems.count == 1 { addSplitViewItem(NSSplitViewItem(viewController: editMetadataViewController)) }
        } else {
            if let splitViewItem = splitViewItem(for: editMetadataViewController) { removeSplitViewItem(splitViewItem) }
        }
    }
    
    func displayEdit() {
        for item in splitViewItems {
            removeSplitViewItem(item)
        }
        addSplitViewItem(NSSplitViewItem(contentListWithViewController: directoryOutlineViewController))
        addSplitViewItem(NSSplitViewItem(viewController: editMetadataViewController))
    }
    
    func displaySearch() {
        for item in splitViewItems {
            removeSplitViewItem(item)
        }
        addSplitViewItem(NSSplitViewItem(contentListWithViewController: searchViewController))
    }
    
    func displayPerformers() {
        for item in splitViewItems {
            removeSplitViewItem(item)
        }
        addSplitViewItem(NSSplitViewItem(contentListWithViewController: performersViewController))
    }
}
