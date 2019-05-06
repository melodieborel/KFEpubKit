//
//  mbBooksViewController.swift
//  mbBooks
//
//  Created by Mélodie Borel on 02/05/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import KFToolbar
import Cocoa


class mbBooksViewController: NSViewController, mbBooksControllerDelegate {
    
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var bottomToolbar: KFToolbar!
    @IBOutlet weak var myWindow: NSWindow!
    @IBOutlet weak var theScroll: NSScrollView!
    
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    private var strokeTextAttributes = [
        NSAttributedString.Key.strokeColor : NSColor.white,
        NSAttributedString.Key.foregroundColor : NSColor.white,
        NSAttributedString.Key.strokeWidth : -2.0,
        NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 18)
        ] as [NSAttributedString.Key : Any]
    private var currenttext: NSMutableAttributedString = NSMutableAttributedString(string: "test")
    
    private var epubController: mbBooksController?
    private var libraryURL: URL?
    private var spineIndex: Int = 11
    private var spineMax: Int = 0
    
    private var contentModel: mbBooksContentModel?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        
        textView.linkTextAttributes = strokeTextAttributes
        textView.textStorage?.setAttributedString(currenttext);
        theScroll.verticalPageScroll = 0.0
        
        var error: Error? = nil
        var dataIsStale: Bool
        let previousSpine = KFToolbarItem(icon: NSImage(named: NSImage.goLeftTemplateName), tag: 0)
        previousSpine!.toolTip = NSLocalizedString("Previous", comment: "")
        previousSpine!.keyEquivalent = "a"
        previousSpine!.keyEquivalentModifierMask = 48 //option
        
        let nextSpine = KFToolbarItem(icon: NSImage(named: NSImage.goRightTemplateName), tag: 1)
        nextSpine!.toolTip = NSLocalizedString("Next", comment: "")
        nextSpine!.keyEquivalent = "s"
        nextSpine!.keyEquivalentModifierMask = 48 //option
        
        bottomToolbar.leftItems = [previousSpine!]
        bottomToolbar.rightItems = [nextSpine!]
        
        bottomToolbar.setItemSelectionHandler({ (selectionType, toolbarItem, tag) in
            switch tag {
            case 0:
                if self.spineIndex > 1 {
                    self.spineIndex -= 1
                    self.updateContent(forSpineIndex: self.spineIndex)
                }
            case 1:
                if self.spineIndex < self.spineMax {
                    self.spineIndex += 1
                    print(self.spineIndex)
                    self.updateContent(forSpineIndex: self.spineIndex)
                }
            default:
                break
            }
        })
        
        textView!.textContainerInset = NSMakeSize(40.0, 40.0)
        let securityBookmark = try! UserDefaults.standard.string(forKey: "mbBooksFolder")
        NSLog("security bookmark is \(securityBookmark)");
        if (securityBookmark != nil){
            
            libraryURL = URL(fileURLWithPath:  securityBookmark!, isDirectory: true)
            NSLog("\(libraryURL)")
            testEpubsInMainBundleResources()
            
        } else {
            requestLibraryURL()
            
        }
        
    }
    
    override func viewDidAppear() {
        //self.view.window?.title = self.contentModel?.metaData["title"] as! String
        //print("the title is \(self.contentModel?.metaData["title"])")
    }
    
    func requestLibraryURL() {
        let panel = NSOpenPanel()
        
        panel.title = "Select or create a library folder"
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        //panel.delegate = self as! NSOpenSavePanelDelegate;
        
        panel.begin(completionHandler: { result in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                for fileURL in panel.urls {
                    self.libraryURL = fileURL
                    UserDefaults.standard.setValue(self.libraryURL?.path, forKey: "mbBooksFolder")
                }
                self.testEpubsInMainBundleResources()
            }
        })
    }
    
    
    func testEpubsInMainBundleResources() {
        let moc = appDelegate.managedObjectContext
        let booksFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Books")
        do {
            let allBooks = try moc.fetch(booksFetch) as! [mbBooksContentModel]
            print("I found a book : \(allBooks)")
            if (allBooks == []) {
                print("there is no book so i import one")
            //}
                let epubURL = URL(fileURLWithPath: "/Users/MB/Desktop/GoT/AGameOfThrones.epub")
                libraryURL!.startAccessingSecurityScopedResource()
                epubController = mbBooksController(epubURL: epubURL, andDestinationFolder: libraryURL?.appendingPathComponent(epubURL.deletingPathExtension().lastPathComponent))
                epubController!.delegate = self
                epubController!.openAsynchronous(false)
            }
            
            else {
                    
                let chapsFetch = NSFetchRequest<mbChapters>(entityName: "Chapters")
                let allchaphrefs = try moc.fetch(chapsFetch)
                self.spineMax = allchaphrefs.count
                    
                self.contentModel = allBooks[0]
                updateContent(forSpineIndex: self.spineIndex)
                /** to erase all books
                    for item in allBooks {
                        moc.delete(item)
                    }
                    // Save Changes
                    try moc.save()
                    */
                }
        } catch {
            fatalError("Failed to fetch any book: \(error)")
        }
    }
    
    func updateContent(forSpineIndex currentSpineIndex: Int) {

        let moc = appDelegate.managedObjectContext

        do {

            let chapsFetch = NSFetchRequest<mbChapters>(entityName: "Chapters")
            chapsFetch.predicate = NSPredicate(format: "chapNo = %@", argumentArray: [self.spineIndex])
            let thechaphref = try moc.fetch(chapsFetch)
            
            
            
            let contentURL = URL(fileURLWithPath: self.contentModel!.mbBookPath!).appendingPathComponent("OEBPS").appendingPathComponent(thechaphref[0].chapterPath)

            var dict: NSDictionary? = [:]
        
            let theAttributedString = NSMutableAttributedString(url: contentURL as! URL, documentAttributes: &dict)

        strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : NSColor.white,
            NSAttributedString.Key.foregroundColor : NSColor.white,
            NSAttributedString.Key.strokeWidth : -2.0,
            NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 52)
            ] as [NSAttributedString.Key : Any]
        
        do {
            let output = theAttributedString
            
            let factor = 4
            output!.beginEditing()
            output!.enumerateAttribute(NSAttributedString.Key.font,
                                       in: NSRange(location: 0, length: output!.length),
                                      options: []) { (value, range, stop) -> Void in
                                         let oldFont = value as? NSFont
                                        let newFont = NSFont(descriptor: oldFont!.fontDescriptor, size: oldFont!.pointSize * CGFloat(factor))
                                        output!.removeAttribute(NSAttributedString.Key.font, range: range)
                                        output!.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
            }
            output!.endEditing()

            try! theAttributedString!.addAttribute(.foregroundColor, value: NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1), range: NSRange(location: 0, length: theAttributedString!.length))
        } catch {}
        textView!.textStorage?.setAttributedString(theAttributedString!)
        textView.linkTextAttributes = strokeTextAttributes
        } catch {
            fatalError("Failed to fetch any chapter: \(error)")
        }
    }
    
    
    // MARK: KFEpubControllerDelegate Methods
    
    func epubController(_ controller: mbBooksController?, willOpenEpub epubURL: URL?) {
        print("will open epub")
    }
    
    
    func epubController(_ controller: mbBooksController?, didOpenEpub contentModel: mbBooksContentModel?) {
        self.contentModel = contentModel
        spineIndex = 11
        updateContent(forSpineIndex: spineIndex)
    }
    
    func epubController(_ controller: mbBooksController?, didFailWithError error: Error?) {
        let description = error.debugDescription
        print("epubController:didFailWithError: \(description)")
    }
}
