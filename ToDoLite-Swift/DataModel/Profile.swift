//
//  Profile.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/11/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  Profile.h and Profile.m
//  Created by Chris Anderson on 11/15/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.

// This does not work because Swift has no equivalent of @dynamic properties which the MYDynamicObject class needs
// The nearest is NSManaged but that is reserved for CoreData; no general solution here

import Foundation

let kProfileDocType = "profile"
let kPrefProfileDocId = "MyProfileDocID"

// I can't think of why I need this alias, but directly using CBLDocument fails
// so does moving it inside the class definition!
typealias CBLDocType = CBLDocument

class Profile: CBLModel {

    var name: String
    var user_id: String
    let type: String = kProfileDocType

    class func queryProfilesInDatabase(db: CBLDatabase) -> CBLQuery? {
        let view = db.viewNamed("profiles")
        if !view?.mapBlock {
            view!.setMapBlock({doc, emit in
                if (kProfileDocType == doc["type"] as NSString) {
                    emit(doc["name"], nil)
                }},
                reduceBlock: nil, version: "1")
        }
        return view?.createQuery()
    }
    
    class func profileInDatabase(db: CBLDatabase, userID: String) -> Profile? {
        let profileDocId = "p:\(userID)"
        var doc: CBLDocType?
        if !profileDocId.isEmpty {
            doc = db.existingDocumentWithID(profileDocId)
        }
        return CBLModel(forDocument: doc) as? Profile
    }
    
    func description() -> String {
        return "\(self.dynamicType) [\(self.document.abbreviatedID) \(self.user_id)]"
    }
    
    init(inDatabase db: CBLDatabase, name: String, userID: String) {
        self.name = name
        self.user_id = userID
        
        let doc = db.documentWithID("p:\(userID)")
        super.init(document: doc)
    }
    
    // make a new Profile model object from a Profile document object
    init(document: CBLDocType!) {
        let n: AnyObject! = document["name"]
        if n {
            self.name = n! as String
        } else {
            self.name = ""
        }
        let i: AnyObject! = document["_id"]
        let u = i as? String
        let un = u?.substringFromIndex(2)
        if un {
            self.user_id = un!
        } else {
            self.user_id = ""
        }
        super.init(document: document)
    }
}
