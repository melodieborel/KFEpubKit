//
//  mbBooksViewController.swift
//  mbBooks
//
//  Created by Mélodie Borel on 02/05/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import KFToolbar


class mbBooksViewController: NSViewController, mbBooksControllerDelegate {
    
    @IBOutlet weak var textView: NSTextView!
    @IBOutlet weak var bottomToolbar: KFToolbar!
    
    private var strokeTextAttributes = [
        NSAttributedString.Key.strokeColor : NSColor.white,
        NSAttributedString.Key.foregroundColor : NSColor.white,
        NSAttributedString.Key.strokeWidth : -2.0,
        NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: 18)
        ] as [NSAttributedString.Key : Any]
    private var currenttext: NSMutableAttributedString = NSMutableAttributedString(string: "test")
    
    private var epubController: mbBooksController?
    private var libraryURL: URL?
    private var spineIndex: Int = 0
    private var contentModel: mbBooksContentModel?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        //NavigationOutline.reloadData()
        
        
        /**
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineBreakMode = NSLineBreakByTruncatingTail;
        [text addAttribute:NSParagraphStyleAttributeName
        value:style
        range:NSMakeRange(0, text.length)];
        */
        textView.linkTextAttributes = strokeTextAttributes
        textView.textStorage?.setAttributedString(currenttext);
        
        
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
                if self.spineIndex < self.contentModel!.spine.count {
                    self.spineIndex += 1
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
        let epubURL = URL(fileURLWithPath: "/Users/MB/Desktop/GoT/AGameOfThrones.epub")
        
        libraryURL!.startAccessingSecurityScopedResource()
        epubController = mbBooksController(epubURL: epubURL, andDestinationFolder: libraryURL)
        epubController!.delegate = self
        epubController!.openAsynchronous(false)
    }
    
    func updateContent(forSpineIndex currentSpineIndex: Int) {
        let theFile = contentModel!.manifest.object(forKey: contentModel!.spine[currentSpineIndex]) as! NSDictionary
        let contentFile = theFile.object(forKey: "href") as! String
        let contentURL = epubController?.epubContentBaseURL!.appendingPathComponent(contentFile)
        NSLog("the contentURL \(contentURL)\n\n")
        
        
        /**let modifiedFont = NSString(format:"<span style=\"font-family: \(self.font!.fontName); font-size: \(self.font!.pointSize)\">%@</span>" as NSString, text)
        let modifiedFont = NSString(format:"<span font-size: 46\">%@</span>" as NSString, text)
        
        let attrStr = try! NSAttributedString(
            data: modifiedFont.data(using: String.Encoding.unicode.rawValue, allowLossyConversion: true)!,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType:NSAttributedString.DocumentType.html, NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)
*/
        var dict: NSDictionary? = [:]
        
        let theAttributedString = NSMutableAttributedString(url: contentURL!, documentAttributes: &dict)
        print(dict)
        
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
            
            //let data = NSData(contentsOf: contentURL!)
            //try! let theAttributedString = NSMutableAttributedString(html: data, documentAttributes: strokeTextAttributes)
            try! theAttributedString!.addAttribute(.foregroundColor, value: NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1), range: NSRange(location: 0, length: theAttributedString!.length))
            //try! theAttributedString!.setAttributes(strokeTextAttributes, range: NSRange(location: 0, length: theAttributedString!.length))
        } catch {}
        textView!.textStorage?.setAttributedString(theAttributedString!)
        textView.linkTextAttributes = strokeTextAttributes
    }
    
    
    // MARK: KFEpubControllerDelegate Methods
    
    func epubController(_ controller: mbBooksController?, willOpenEpub epubURL: URL?) {
        print("will open epub")
    }
    
    
    func epubController(_ controller: mbBooksController?, didOpenEpub contentModel: mbBooksContentModel?) {
        self.view.window?.title = contentModel?.metaData["title"] as! String
        self.contentModel = contentModel
        spineIndex = 1
        updateContent(forSpineIndex: spineIndex)
    }
    
    func epubController(_ controller: mbBooksController?, didFailWithError error: Error?) {
        let description = error.debugDescription
        print("epubController:didFailWithError: \(description)")
    }
}
