//
//  mbBooksConstants.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation

@objc public enum mbBooksBookType: Int16 {
    case Unknown
    case Epub2
    case Epub3
    case iBook
}

public enum mbBooksBookEncryption: Int16 {
    case None
    case Fairplay
}

public let mbBooksErrorDomain :NSString = "mbBooksErrorDomain";

public class mbBooksConstants: NSObject {
    
 }

let VALID_FILE_TYPES = ["epub"]
