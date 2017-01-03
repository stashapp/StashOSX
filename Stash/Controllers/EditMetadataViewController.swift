//
//  EditMetadataViewController.swift
//  Stash
//
//

import Cocoa

// TODO: Move this somewhere else?  Make it a subclass?
/*
 http://blog.bjhomer.com/2014/08/nsscrollview-and-autolayout.html
 http://stackoverflow.com/questions/29241474/enabling-nsscrollview-to-scroll-its-contents-using-auto-layout-in-interface-buil
 http://stackoverflow.com/questions/2736039/nsscrollview-frame-and-flipped-documentview
 */
extension NSStackView {
    open override var isFlipped: Bool {
        return true
    }
}

class EditMetadataViewController: NSViewController, NSTokenFieldDelegate, NSComboBoxDataSource {
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var hashTextField: NSTextField!
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var urlTextField: NSTextField!
    @IBOutlet weak var studioComboBox: NSComboBox!
    @IBOutlet weak var galleryHashTextField: NSTextField!
    @IBOutlet weak var performersTokenField: NSTokenField!
    @IBOutlet weak var tagsTokenField: NSTokenField!
    @IBOutlet weak var descriptionTextView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = NSApp.delegate as! AppDelegate
        let treeController = delegate.directoryTreeController
        
//        directoryOutlineView.exposedBindings
        hashTextField.bind(NSValueBinding, to: treeController, withKeyPath: "selection.fileHash", options: [NSNullPlaceholderBindingOption: "No Hash"])
        titleTextField.bind(NSValueBinding, to: treeController, withKeyPath: "selection.title", options: [NSNullPlaceholderBindingOption: "Title"])
        urlTextField.bind(NSValueBinding, to: treeController, withKeyPath: "selection.url", options: [NSNullPlaceholderBindingOption: "URL"])
        studioComboBox.bind(NSValueBinding, to: treeController, withKeyPath: "selection.studio", options: [NSNullPlaceholderBindingOption: "Studio"])
        galleryHashTextField.bind(NSValueBinding, to: treeController, withKeyPath: "selection.gallery", options: [NSNullPlaceholderBindingOption: "Gallery Hash"])
        performersTokenField.bind(NSValueBinding, to: treeController, withKeyPath: "selection.performers", options: [NSNullPlaceholderBindingOption: "Performers", NSContinuouslyUpdatesValueBindingOption: true])
        tagsTokenField.bind(NSValueBinding, to: treeController, withKeyPath: "selection.tags", options: [NSNullPlaceholderBindingOption: "Tags"])
        descriptionTextView.bind(NSValueBinding, to: treeController, withKeyPath: "selection.details", options: [NSNullPlaceholderBindingOption: "Description"])
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        titleTextField.invalidateIntrinsicContentSize()
    }
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [Any]? {
        switch tokenField {
        case performersTokenField:
            return Database.shared.performersAsStrings(startingWith: substring)
        case tagsTokenField:
            return Database.shared.tagsAsStrings(startingWith: substring)
        default:
            return nil
        }
    }
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        let studios = Database.shared.studios(startingWith: comboBox.stringValue)
        return studios.count < 4 ? studios.count : 4
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        let studios = Database.shared.studios(startingWith: comboBox.stringValue)
        return studios.count > index ? studios[index].name : nil
    }
}
