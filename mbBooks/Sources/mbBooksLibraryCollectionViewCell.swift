//
//  mbBooksLibraryCollectionViewCell.swift
//  mbBooks
//
//  Created by Mélodie Borel on 08/05/2019.
//

import Foundation
import Cocoa

class mbBooksLibraryCollectionViewCell: NSCollectionViewItem {
    
    @IBOutlet var bookImage: NSImageView!
    @IBOutlet var bookLabel: NSTextField!


    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.lightGray.cgColor
    }

    
    func displayContent(image: NSImage, title: String){
        bookImage.image = image
        bookLabel.stringValue = title
    }
}

extension NSUserInterfaceItemIdentifier {
    static let collectionViewItem = NSUserInterfaceItemIdentifier("mbCollectionViewItem")
}

