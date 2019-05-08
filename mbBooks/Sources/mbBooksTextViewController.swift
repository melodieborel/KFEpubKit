//
//  mbBooksTextViewController.swift
//  mbBooks
//
//  Created by Mélodie Borel on 07/05/2019.
//  Copyright © 2019 KF Interactive. All rights reserved.
//

import Foundation
import Cocoa

class mbBooksTextViewController: NSTextView {
    override func keyDown(with theEvent: NSEvent) // A key is pressed
    {
        if theEvent.keyCode == 125 //bas
        {

        }
        else if theEvent.keyCode == 126 //haut
        {

        }
        print("Key with number: \(theEvent.keyCode) was pressed")
    }
}
