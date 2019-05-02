//
//  mbBooksExtractor.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import SSZipArchive

@objc protocol mbBooksExtractorDelegate: NSObjectProtocol {
    func epubExtractorDidFinishExtracting(_ epubExtractor: mbBooksExtractor?)
    func epubExtractor(_ epubExtractor: mbBooksExtractor?, didFailWithError error: Error?)
    
    @objc optional func epubExtractorDidStartExtracting(_ epubExtractor: mbBooksExtractor?)
    @objc optional func epubExtractorDidCancelExtraction(_ epubExtractor: mbBooksExtractor?)
}

class mbBooksExtractor: NSObject {
    weak var delegate: mbBooksExtractorDelegate?
    private(set) var epubURL: URL?
    private(set) var destinationURL: URL?
    private let operationQueue: OperationQueue = OperationQueue()
    
    init(epubURL: URL?, andDestinationURL destinationURL: URL?) {
        super.init()
        self.epubURL = epubURL
        self.destinationURL = destinationURL
    }

    
    func start(_ asynchronous: Bool) -> Bool {
        var didSucceed: Bool = false
        if (delegate != nil) {
            if delegate!.responds(to: #selector(delegate!.epubExtractorDidStartExtracting(_:))) {
                delegate?.epubExtractorDidStartExtracting!(self)
            }
            
            if asynchronous {
                operationQueue.addOperation({OperationQueue.main.addOperation({
                    didSucceed = SSZipArchive.unzipFile(atPath: self.epubURL!.path, toDestination: self.destinationURL!.path)
                    NSLog("did succeed \(didSucceed)")
                })})
            operationQueue.addOperation({OperationQueue.main.addOperation({self.perform(#selector(self.doneExtracting(_:)), with: NSNumber(value: didSucceed), afterDelay: 0.0)})})
                
                return true
            } else {
                didSucceed = SSZipArchive.unzipFile(atPath: epubURL!.path, toDestination: destinationURL!.path)
                doneExtracting(NSNumber(value: didSucceed))
                return true
 
            }
        } else {
            return false
        }
    }
    
    @objc func doneExtracting(_ didSuceed: NSNumber?) {
        if didSuceed?.boolValue ?? false {
            delegate!.epubExtractorDidFinishExtracting(self)
        } else {
            let error = NSError(domain: mbBooksErrorDomain as String, code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Could not extract ebup file."
                ])
            delegate!.epubExtractor(self, didFailWithError: error)
        }
    }
    
    func cancel() {
        operationQueue.cancelAllOperations()
        if delegate!.responds(to: #selector(delegate!.epubExtractorDidCancelExtraction(_:))) {
            delegate?.epubExtractorDidCancelExtraction!(self)
        }
    }
    
}


