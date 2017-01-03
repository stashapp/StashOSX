//
//  PerformersViewController.swift
//  Stash
//
//

import Cocoa
import FileKit

class PerformersViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource {
    let scrollView = NSScrollView()
    let collectionView = NSCollectionView()
    let addButton = NSButton()
    
    private var performers: [Performer] = []
    
    override func loadView() {
        view = NSView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        scrollView.addSubview(collectionView)
        scrollView.documentView = collectionView
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isSelectable = true
        let nib = NSNib(nibNamed: "PerformerCollectionViewItem", bundle: nil)
        collectionView.register(nib, forItemWithIdentifier: "PerformerCollectionViewItem")
        configureCollectionView()
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.target = self
        addButton.action = #selector(tappedAddButton(_:))
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            
            collectionView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            
            addButton.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            addButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8)
        ])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        updatePerformers()
        collectionView.reloadData()
    }
    
    @objc fileprivate func tappedAddButton(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowedFileTypes = ["jpg", "png"]
        openPanel.title = "Choose a performer image"
        openPanel.message = "Choose a performer image"
        openPanel.beginSheetModal(for: NSApp.mainWindow!, completionHandler: { result in
            if result == NSFileHandlingPanelOKButton, let url = openPanel.url {
                Stash.addPerformer(imageUrl: url)
            }
        })
    }
    
    private func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        collectionView.collectionViewLayout = flowLayout
//        view.wantsLayer = true
//        collectionView.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    private func updatePerformers() {
        do {
            performers = try Database.shared.viewContext.fetch(Performer.fetchRequest())
        } catch {
            fatalError("Boom")
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return performers.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: "PerformerCollectionViewItem", for: indexPath)
        let performer = performers[indexPath.item]
        item.imageView?.image = Stash.Images.performer(withChecksum: performer.checksum!)
        item.textField?.stringValue = performers[indexPath.item].name ?? ""
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        let performer = performers[indexPath.item]
        
        PerformerViewController.present(from: self, performer: performer, callback: {
            collectionView.reloadData()
        })
    }
    
}
