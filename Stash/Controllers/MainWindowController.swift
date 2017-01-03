//
//  MainWindowController.swift
//  Stash
//
//

import Cocoa
import FileKit

class MainWindowController: NSWindowController {
    @IBOutlet weak var refreshProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var refreshInfoButton: NSButton!
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    @IBOutlet weak var saveButton: NSButton!
    var refreshNotificationObject: RefreshNotificationObject?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.titleVisibility = .hidden
//        self.window?.toolbar
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshStarted(notification:)), name: NSNotification.Name(rawValue: "refreshStarted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCompleted(notification:)), name: NSNotification.Name(rawValue: "refreshCompleted"), object: nil)
    }
    
    private func getMainContainerViewController() -> MainContainerViewController {
        return window?.contentViewController as! MainContainerViewController
    }
    
    @IBAction func tappedRefreshButton(_ sender: NSToolbarItem) {
        let appDelegate = NSApp.delegate as! AppDelegate
        appDelegate.refresh()
    }
    
    @IBAction func tappedRefreshProgressIndicator(_ sender: NSToolbarItem) {
        let refreshProgressViewController = window?.windowController?.storyboard?.instantiateController(withIdentifier: "RefreshProgressViewController") as! RefreshProgressViewController
        refreshProgressViewController.refreshNotificationObject = refreshNotificationObject
        window?.contentViewController?.presentViewControllerAsSheet(refreshProgressViewController)
    }
    
    @IBAction func tappedSaveButton(_ sender: NSToolbarItem) {
        let operation = SaveJSONOperation()
        operation.start()
    }
    
    @IBAction func segmentedControlTapped(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            getMainContainerViewController().displaySearch()
        case 1:
            getMainContainerViewController().displayEdit()
        case 2:
            getMainContainerViewController().displayPerformers()
        default:
            getMainContainerViewController().displaySearch()
        }
    }
    
    @objc private func refreshStarted(notification: Notification) {
        refreshInfoButton.isHidden = false
        refreshNotificationObject?.progress.removeObserver(self, forKeyPath: #keyPath(NSProgress.localizedAdditionalDescription))
        refreshNotificationObject = notification.object as? RefreshNotificationObject
        refreshNotificationObject?.progress.addObserver(self, forKeyPath: #keyPath(NSProgress.localizedAdditionalDescription), options: .initial, context: nil)
    }
    
    @objc private func refreshCompleted(notification: Notification) {
        // TODO: Make a custom view with progress bar + button that is tappable
        refreshInfoButton.isHidden = true
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(NSProgress.localizedAdditionalDescription) {
            DispatchQueue.main.async { [weak self] in
                guard let progress = object as? Progress else { return }
                self?.refreshProgressIndicator.doubleValue = progress.fractionCompleted
                
                if progress.fractionCompleted >= 1 {
                    self?.refreshProgressIndicator.stopAnimation(nil)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
