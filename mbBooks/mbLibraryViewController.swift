//
//  mbLibraryViewController.swift
//  mbBooks
//
//  Created by Mélodie Borel on 04/05/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import Cocoa

class mbLibraryViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    

    @IBOutlet weak var collectionView: NSCollectionView!
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        let moc = appDelegate.managedObjectContext
        let booksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        do {
            let allBooks = try moc.fetch(booksFetch) as! [mbBooksContentModel]
            return allBooks.count
        } catch {
            fatalError("Failed to fetch any book: \(error)")
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let moc = appDelegate.managedObjectContext
        let booksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Book")
        do {
            let allBooks = try moc.fetch(booksFetch) as! [mbBooksContentModel]
            let itemPath = allBooks[indexPath.section].coverPath
            let item = NSImage(byReferencing: NSURL(string: itemPath!) as! URL)
            return item as! NSCollectionViewItem
        } catch {
            fatalError("Failed to fetch any book: \(error)")
        }
    }
    
    
    fileprivate func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        collectionView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
        collectionView.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        configureCollectionView()
        
    }
    
    override func viewDidAppear() {

    }
    
}
