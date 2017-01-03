//
//  SearchViewController.swift
//  Stash
//
//

import Cocoa

class SearchViewController: NSViewController {
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var searchButton: NSButton!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var pageNumberTextField: NSTextField!
    @IBOutlet weak var pageNumberLabel: NSTextField!
    @IBOutlet weak var previousButton: NSButton!
    @IBOutlet weak var nextButton: NSButton!
    
    var scenes: [Scene] = []
    var page: Int = 0
    let pageSize: Int = 40

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = Database.shared.persistentContainer
        
        tableView.delegate = self
        tableView.dataSource = self
        
        configurePredicateEditor()
        configureTableView()
        
        resetPredicate()
    }
    
    @IBAction func tappedSearchButton(_ sender: NSButton) {
        updateData()
    }
    
    @IBAction func tappedResetButton(_ sender: NSButton) {
        resetPredicate()
    }
    
    @IBAction func tappedPreviousButton(_ sender: NSButton) {
        let pageNum = pageNumberTextField.integerValue - 1
        pageNumberTextField.integerValue = pageNum > 0 ? pageNum : 1
        updateData()
    }
    
    @IBAction func tappedNextButton(_ sender: NSButton) {
        let pageNum = pageNumberTextField.integerValue + 1
        pageNumberTextField.integerValue = pageNum <= numberOfPages() ? pageNum : numberOfPages()
        updateData()
    }
    
    @IBAction func updatedPredicate(_ sender: NSPredicateEditor) {
        updateData()
    }
    
    @IBAction func updatedPageTextField(_ sender: NSTextField) {
        updateData()
    }
    
    private func configurePredicateEditor() {
        predicateEditor.formattingDictionary = [
            "%[details, checksum, path, studio.name]@ %[contains, is, is not]@ %@": "%[Details, Checksum, Path, Studio]@ %[contains, is, is not]@ %@",
            "%[title]@ %[contains]@ %@": "%[Title]@ %[search]@ %@",
            "%[title]@ %[is]@ <null>": "%[Title]@ %[is null]@",
            "%[performers.name]@ %[is, contains]@ %@": "%[Performers]@ %[has performer, search]@ %@",
            "%[tags.name]@ %[is, contains]@ %@": "%[Tags]@ %[has tag, search]@ %@"
        ]
        
        let titleTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: #keyPath(Scene.title))], rightExpressionAttributeType: .stringAttributeType, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.contains.rawValue)], options: Int(NSComparisonPredicate.Options.caseInsensitive.rawValue))
        
        // TODO: Subclass to make a custom nil row
        let titleNilTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: #keyPath(Scene.title))], rightExpressions: [NSExpression(forConstantValue: NSNull())], modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.equalTo.rawValue)], options: 0)
        
        let detailsTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: #keyPath(Scene.details))], rightExpressionAttributeType: .stringAttributeType, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.contains.rawValue)], options: Int(NSComparisonPredicate.Options.caseInsensitive.rawValue))

        
        let checksumTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: #keyPath(Scene.checksum))], rightExpressionAttributeType: .stringAttributeType, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.equalTo.rawValue)], options: 0)
        
        let pathTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: #keyPath(Scene.path))], rightExpressionAttributeType: .stringAttributeType, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.contains.rawValue)], options: Int(NSComparisonPredicate.Options.caseInsensitive.rawValue))
        
        var studioExpressions: [NSExpression] = [NSExpression(forConstantValue: "")]
        for studio in Database.shared.studios() {
            studioExpressions.append(NSExpression(forConstantValue: studio.name))
        }
        let studioTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: #keyPath(Scene.studio.name))], rightExpressions: studioExpressions, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.equalTo.rawValue)], options: 0)
        
        var performerExpressions: [NSExpression] = [NSExpression(forConstantValue: "")]
        for performer in Database.shared.performers() {
            performerExpressions.append(NSExpression(forConstantValue: performer.name))
        }
        let performersTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: "performers.name")], rightExpressions: performerExpressions, modifier: .any, operators: [NSNumber(value: NSComparisonPredicate.Operator.equalTo.rawValue)], options: 0)
        
        let performersSearchTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: "performers.name")], rightExpressionAttributeType: .stringAttributeType, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.contains.rawValue)], options: Int(NSComparisonPredicate.Options.caseInsensitive.rawValue))
        
        let tagsSearchTemplate = NSPredicateEditorRowTemplate(leftExpressions: [NSExpression(forKeyPath: "tags.name")], rightExpressionAttributeType: .stringAttributeType, modifier: .direct, operators: [NSNumber(value: NSComparisonPredicate.Operator.contains.rawValue)], options: Int(NSComparisonPredicate.Options.caseInsensitive.rawValue))
        
        let compoundTypes: [NSNumber] = [
            NSNumber(value: NSCompoundPredicate.LogicalType.and.rawValue),
            NSNumber(value: NSCompoundPredicate.LogicalType.or.rawValue)
        ]
        let compoundTemplate = NSPredicateEditorRowTemplate(compoundTypes: compoundTypes)
        
        predicateEditor.rowTemplates = [compoundTemplate, titleTemplate, titleNilTemplate, detailsTemplate, checksumTemplate, pathTemplate, studioTemplate, performersTemplate, performersSearchTemplate, tagsSearchTemplate]
        
//        let data = predicateEditor.perform(Selector(extendedGraphemeClusterLiteral: "_generateFormattingDictionaryStringsFile")).takeRetainedValue() as! Data
//        print(String(data: data, encoding: .unicode))
    }
    
    private func configureTableView() {
        tableView.register(NSNib(nibNamed: "SceneTableCellView", bundle: nil), forIdentifier: "SceneTableCellView")
    }
    
    private func resetPredicate() {
        predicateEditor.objectValue = NSCompoundPredicate(andPredicateWithSubpredicates: [NSCompoundPredicate(format: "details CONTAINS[c] ''")])
    }
    
    private func updateData() {
        guard let predicate = predicateEditor.predicate else { return }
        scenes = Database.shared.scenes(fromPredicate: predicate)
        scenes.sort(by: { left, right in
            let leftTitle = left.title ?? ""
            let rightTitle = right.title ?? ""
            return leftTitle.localizedStandardCompare(rightTitle) == .orderedAscending
        })
        // TODO: Do I need the ANY at the start? http://stackoverflow.com/questions/1415033/nspredicateeditor-and-relationships
//        scenes = Database.shared.scenes(fromPredicate: NSPredicate(format: "ANY tags.name CONTAINS[c] 'iPhone'"))
        
        // Set up page labels and get current page
        if pageNumberTextField.integerValue > 0 && pageNumberTextField.integerValue <= numberOfPages() {
            page = pageNumberTextField.integerValue - 1
        } else {
            page = 0
        }
        pageNumberLabel.stringValue = "Page \(page + 1) of \(numberOfPages())"
        
        tableView.reloadData()
    }
    
    fileprivate func getScene(atRow row: Int, forPage page: Int) -> Scene {
        var index = row + (page * pageSize)
        if index >= scenes.count {
            index = scenes.count - 1
        }
        
        return scenes[index]
    }
    
    fileprivate func numberOfPages() -> Int {
        let pages = ceil(Double(scenes.count) / Double(pageSize))
        return pages > 0 ? Int(pages) : 1
    }
    
}

extension SearchViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if scenes.count == 0 { return 0 }
        
        if page + 1 < numberOfPages() {
            return pageSize
        } else {
            let c = (pageSize * (page + 1)) - scenes.count
            return c == 0 ? pageSize : pageSize - c
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.make(withIdentifier: "SceneTableCellView", owner: nil) as? SceneTableCellView else { return nil }
        
        let scene = getScene(atRow: row, forPage: page)
        
        cell.configure(scene)
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let cell = tableView.make(withIdentifier: "SceneTableCellView", owner: nil) as? SceneTableCellView else { return 100 }
        
        let scene = getScene(atRow: row, forPage: page)
        cell.configure(scene)
        
        return cell.fittingSize.height
    }
    
    func tableViewColumnDidResize(_ notification: Notification) {
        tableView.reloadData()
    }
}
