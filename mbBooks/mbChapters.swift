//
//  mbChapters.swift
//  
//
//  Created by Mélodie Borel on 05/05/2019.
//
//

import Foundation
import CoreData


public class mbChapters: NSManagedObject {
    
    @NSManaged var chapterPath: String
    @NSManaged var chapNo: Int32
    
    @NSManaged var fromBook: mbBooksContentModel

}
