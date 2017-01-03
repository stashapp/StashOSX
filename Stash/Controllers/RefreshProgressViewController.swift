//
//  RefreshProgressViewController.swift
//  Stash
//
//

import Cocoa
import FileKit

class RefreshProgressViewController: NSViewController {
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var additionalDescriptionTextField: NSTextField!
    
    var refreshNotificationObject: RefreshNotificationObject?
    
    deinit {
        refreshNotificationObject?.progress.removeObserver(self, forKeyPath: #keyPath(NSProgress.localizedAdditionalDescription))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshNotificationObject?.progress.addObserver(self, forKeyPath: #keyPath(NSProgress.localizedAdditionalDescription), options: .initial, context: nil)
        
        // TODO: Add a cancel button and cancel the operation on the refreshNoticiationObject
    }
    
    @IBAction func tappedCloseButton(sender: NSButton) {
        dismissViewController(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(NSProgress.localizedAdditionalDescription) {
            DispatchQueue.main.async { [weak self] in
                guard let progress = object as? Progress else { return }
                self?.progressIndicator.doubleValue = progress.fractionCompleted
                self?.descriptionTextField.stringValue = progress.localizedDescription
                self?.additionalDescriptionTextField.stringValue = progress.localizedAdditionalDescription
                
                if progress.fractionCompleted >= 1 {
                    self?.progressIndicator.stopAnimation(nil)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
}
