//
//  mbBooksController.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation

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
    private(set) var contentModel: mbBooksContentModel?
    private var extractor: mbBooksExtractor?
    private var parser: mbBooksParser?
    
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

        
        var error: Error? = nil
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
            contentModel = mbBooksContentModel()
            
            contentModel!.bookType = parser!.bookType(forBaseURL: destinationURL)
            contentModel!.bookEncryption = parser!.contentEncryption(forBaseURL: destinationURL)
            contentModel!.metaData = parser!.metaData(from: document)!
            contentModel!.coverPath = parser!.coverPathComponent(from: document)!
            contentModel!.isRTL = parser!.isRTL(from: document)
            
            if contentModel?.metaData == nil {
                var error = NSError(domain: mbBooksErrorDomain as String, code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "No meta data found"
                    ])
                delegate!.epubController(self, didFailWithError: error)
            } else {
                contentModel!.manifest = parser!.manifest(from: document)!
                contentModel!.spine = parser!.spine(from: document)
                contentModel!.guide = parser!.guide(from: document)!
                if (delegate != nil) {
                    delegate!.epubController(self, didOpenEpub: contentModel)
                }
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
