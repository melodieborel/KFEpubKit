//
//  mbReadings.swift
//  mbBooks
//
//  Created by Mélodie Borel on 25/05/2019.
//

import Foundation
import CoreData


public class mbReadings: NSManagedObject {
    
    @NSManaged var readingDate: NSDate
    @NSManaged var bookMark: Int32
    
    @NSManaged var bookID: mbBooksContentModel
    
}
