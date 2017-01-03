//
//  AppDelegate.swift
//  Stash
//
//

import Cocoa
import FileKit

struct RefreshNotificationObject {
    var progress: Progress
    var scanOperation: ScanOperation
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    lazy var directoryTreeController: NSTreeController = {
        var treeController = NSTreeController()
        treeController.childrenKeyPath = "children"
        treeController.leafKeyPath = "isLeaf"
        treeController.objectClass = FileTreeNode.self
        return treeController
    }()
    
    var refreshProgress: Progress = Progress.discreteProgress(totalUnitCount: -1)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
//        NSApplication.shared().windows[0].contentViewController!.view.wantsLayer = true
        
        Stash.initialize()
        WebServer.initialize()
        // Init this so database is ready right away
        let _ = Database.shared.persistentContainer
        
        FFMPEG.initialize()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCompleted(notification:)), name: NSNotification.Name(rawValue: "refreshCompleted"), object: nil)
        
        if Stash.Paths.mappings.exists && Database.shared.isDatabaseEmpty() {
            debugPrint("Starting JSON import...")
            let operation = ImportJSONOperation()
            operation.completionBlock = { [weak self] in
                guard let this = self else { return }
                this.refresh()
            }
            operation.start()
        } else {
            refresh()
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        let directoryURL = UserDefaults.standard.url(forKey: "stash.directory")
        if directoryURL == nil {
            chooseStashDirectory()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    private func chooseStashDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.title = "Choose a directory"
        openPanel.message = "Choose your directory for your media files"
        openPanel.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { result in
            if result == NSFileHandlingPanelOKButton, let url = openPanel.url {
                UserDefaults.standard.set(url, forKey: "stash.directory")
                self.refresh()
            } else {
                if UserDefaults.standard.url(forKey: "stash.directory") == nil {
                    NSApp.terminate(self)
                }
            }
        })
    }
    
    func refresh() {
        guard let url = UserDefaults.standard.url(forKey: "stash.directory") else { return }
        guard let directoryPath = Path(url: url) else { return }
        
        refreshProgress = Progress.discreteProgress(totalUnitCount: -1)
        let operation = Database.scan(path: directoryPath, progress: refreshProgress)
        let refreshObject = RefreshNotificationObject(progress: refreshProgress, scanOperation: operation)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshStarted"), object: refreshObject)
    }
    
    @IBAction func openNewDirectory(sender: NSMenuItem) {
        chooseStashDirectory()
    }

    @objc fileprivate func refreshCompleted(notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            let directoryURL = UserDefaults.standard.url(forKey: "stash.directory")
            let path = Path(url: directoryURL!)
            let pathNode = FileTreeNode(path!)
            self?.directoryTreeController.content = pathNode
        }
    }
}

