//
//  mbBooksContentModel.swift
//  mbBooks
//
//  Created by Mélodie Borel on 30/04/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import CoreData

class mbBooksContentModel: NSManagedObject {
    
    var metaData: NSMutableDictionary = [:]
    var manifest: NSMutableDictionary = [:]
    var spine: [String] = []
    var guide: [Any] = []
    
    @NSManaged var mbBookTitle: String?
    @NSManaged var mbBookPath: String?
    
    @NSManaged var mbBookType: Int16
    @NSManaged var mbBookEncryption: Int16
    
    @NSManaged var coverPath: String?
    @NSManaged var chapters: NSSet
    
    @NSManaged var isRTL: Bool
    
    @NSManaged var bookMark: Int32
    
}
