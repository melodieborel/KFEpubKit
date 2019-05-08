//
//  mbBooksController.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import CoreData
import Cocoa

@objc protocol mbBooksControllerDelegate: NSObjectProtocol {
    func epubController(_ controller: mbBooksController?, didOpenEpub contentModel: mbBooksContentModel?)
    func epubController(_ controller: mbBooksController?, didFailWithError error: Error?)
    
    @objc optional func epubController(_ controller: mbBooksController?, willOpenEpub epubURL: URL?)
    
}

class mbBooksController: NSObject, mbBooksExtractorDelegate {
    weak var delegate: mbBooksControllerDelegate?
    private(set) var epubURL: URL?
    private(set) var destinationURL: URL?
    private(set) var epubContentBaseURL: URL?
    //private(set) var contentModel: mbBooksContentModel?
    private var extractor: mbBooksExtractor?
    private var parser: mbBooksParser?
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    

    
    init(epubURL: URL?, andDestinationFolder destinationURL: URL?) {
        super.init()
        self.epubURL = epubURL
        self.destinationURL = destinationURL
    }
    
    func openAsynchronous(_ asynchronous: Bool) {
        extractor = mbBooksExtractor(epubURL: epubURL, andDestinationURL: destinationURL)
        extractor!.delegate = self
        extractor!.start(asynchronous)
    }
    
    func epubExtractorDidStartExtracting(_ epubExtractor: mbBooksExtractor?) {
        if delegate!.responds(to: #selector(self.epubController(_:willOpenEpub:))) {
            delegate?.epubController!(self, willOpenEpub: epubURL)
        }
    }
    
    func epubExtractorDidFinishExtracting(_ epubExtractor: mbBooksExtractor?) {
        parser = mbBooksParser()
        let rootFile: URL? = parser!.rootFile(forBaseURL: destinationURL)
        
        if rootFile == nil {
            var error = NSError(domain: mbBooksErrorDomain as String, code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No root file"
                ])
            delegate!.epubController(self, didFailWithError: error)
            return
        }
        
        epubContentBaseURL = rootFile?.deletingLastPathComponent()

        var content: String? = nil
        do {
            content = try String(contentsOf: rootFile!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
        } catch {
        }
        var document: XMLDocument? = nil
        do {
            document = try XMLDocument(xmlString: content ?? "", options: [])
            
        } catch {
        }
        
        if document != nil {
            let managedObjectContext = appDelegate.managedObjectContext
            
            let thisBook = NSEntityDescription.insertNewObject(forEntityName: "Books", into: managedObjectContext) as! mbBooksContentModel
            
            thisBook.mbBookPath = destinationURL?.path
            thisBook.mbBookType = parser!.bookType(forBaseURL: destinationURL).rawValue
            thisBook.mbBookEncryption = parser!.contentEncryption(forBaseURL: destinationURL).rawValue
            
            thisBook.metaData = parser!.metaData(from: document)!
            thisBook.coverPath = parser!.coverPathComponent(from: document)!
            print(thisBook.mbBookPath)
            thisBook.isRTL = parser!.isRTL(from: document)
            
            if thisBook.metaData == nil {
                var error = NSError(domain: mbBooksErrorDomain as String, code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "No meta data found"
                    ])
                delegate!.epubController(self, didFailWithError: error)
            } else {
                thisBook.setValue(thisBook.metaData.value(forKey: "title") as! String, forKey: "mbBookTitle")
                
                thisBook.manifest = parser!.manifest(from: document)!
                thisBook.spine = parser!.spine(from: document)
                thisBook.guide = parser!.guide(from: document)!
                
                for (i,element) in parser!.spine(from: document).enumerated() {
                    
                     let theFile = thisBook.manifest.object(forKey: element) as! NSDictionary
                    
                    let thisChap = NSEntityDescription.insertNewObject(forEntityName: "Chapters", into: managedObjectContext) as! mbChapters
                    thisChap.chapterPath = theFile.object(forKey: "href") as! String
                    thisChap.chapNo = Int32(i)
                    thisChap.fromBook = thisBook
                }

                
                if (delegate != nil) {
                    delegate!.epubController(self, didOpenEpub: thisBook)
                }
            }
            do {
                try managedObjectContext.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
        else {
            var error = NSError(domain: mbBooksErrorDomain as String, code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No document found"
                ])
            delegate!.epubController(self, didFailWithError: error)
        }
    }
    
    func epubExtractor(_ epubExtractor: mbBooksExtractor?, didFailWithError error: Error?) {
        if (delegate != nil) {
            delegate!.epubController(self, didFailWithError: error)
        }
    }
    
    @objc func epubController(_ controller: mbBooksController?, willOpenEpub epubURL: URL?){
        
    }
}
