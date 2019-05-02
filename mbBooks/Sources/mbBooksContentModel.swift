//
//  mbBooksContentModel.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation

class mbBooksContentModel: NSObject {
    
    var bookType: mbBooksBookType?
    var bookEncryption: mbBooksBookEncryption?
    var metaData: NSMutableDictionary = [:]
    var coverPath = ""
    var manifest: NSMutableDictionary = [:]
    var spine: [String] = []
    var guide: [Any] = []
    var isRTL = false
    
}
