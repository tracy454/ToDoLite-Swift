//
//  Titled.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/9/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  Titled.h and Titled.m
//  Created by Jens Alfke on 8/26/13.

// This does not work because Swift has no equivalent of @dynamic properties which the MYDynamicObject class needs
// The nearest is NSManaged but that is reserved for CoreData; no general solution here

import Foundation

/* Abstract superclass for List and Task. */

class Titled: CBLModel {
    var title: String  // Swift strings are 'value' variables, no copying needed
    var created_at: NSDate
    
    // this must be overridden in a subclass to return a valid string
    // Swift won't let a class func or class var be invoked inside the init(...); we tolerate the bit of waste here
    var docType: String {
        get {
            assert(false, "Unimplemented data model object")
            return ""
    }
    }
    
    init(inDatabase database: CBLDatabase, withTitle title: String) {
        // now is good for a default value
        self.created_at = NSDate(timeIntervalSinceNow: 0)
        self.title = title
        super.init(newDocumentInDatabase: database)
        self.setValue(self.docType, ofProperty: "type")
    }
    
    init(document: CBLDocType?) {
        let t: AnyObject? = document?["title"]
        if t {
            self.title = t! as String
            
        } else {
            self.title = ""
        }
        self.created_at = NSDate(timeIntervalSinceNow: 0)
        super.init(document: document)
    }
    
    func description() -> String {
        return "\(self.dynamicType) [\(self.document.abbreviatedID) '\(self.title)']"
    }
}