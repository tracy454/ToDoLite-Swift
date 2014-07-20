//
//  List.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/11/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  List.h and List.m
//  Created by Jens Alfke on 8/22/13.

// This does not work because Swift has no equivalent of @dynamic properties which the MYDynamicObject class needs
// The nearest is NSManaged but that is reserved for CoreData; no general solution here

import Foundation

let kListDocType = "list"

class List: Titled {
    var owner: Profile?
    var members: Array<String> = []

    init(inDatabase database: CBLDatabase, withTitle title: String, owner: Profile?) {
        self.owner = owner
        super.init(inDatabase: database, withTitle: title)
    }
    
    init(document: CBLDocType?) {
        let p: AnyObject? = document?["owner"]
        self.owner = p as? Profile
        super.init(document: document)
    }

    class func queryListsInDatabase(db: CBLDatabase) -> CBLQuery? {
        let view  = db.viewNamed("lists")
        if !view?.mapBlock {
            view.setMapBlock({doc, emit in
                if (doc?["type"] as NSString == kListDocType) {
                    emit(doc?["title"], nil)
                }
                },
                reduceBlock: {keys, values, rereduce in return 0}, version: "1")
        }
        return view?.createQuery()
    }
    
    func queryTasks() -> CBLQuery? {
        let view = self.document?.database?.viewNamed("tasksByDate")
        if !view?.mapBlock {
            // first query is not set up yet
            view!.setMapBlock({doc, emit in
                if (doc?["type"] as NSString == kTaskDocType) {
                    let date: AnyObject? = doc["created_at"]
                    let listID: NSString? = doc?["list_id"] as? NSString
                    emit([listID, date], doc)
                }
                },
                reduceBlock: nil, version: "4") // increase version anytime the MapBlock body is altered
        }
        let query = view?.createQuery()
        let myListId = self.document?.documentID
        if query {
            query!.startKey = [myListId, nil]  // almost certainly won't work, but it builds
            query!.endKey = [myListId]
        }
        return query
    }
    
    
    // this is slightly different than the ObjC version
    class func updateAllListsInDatabase(db: CBLDatabase, withOwner owner: Profile) -> NSError? {
        let listQuery: CBLQuery? = List.queryListsInDatabase(db)
        var err: NSError?
        let myLists = listQuery?.run(&err)
        return err
    }
    
    override var docType: String {
        get {
            return kListDocType
        }
    }
    
    func addTaskWithTitle(title: String, withImage image: NSData?, withImageContentType contentType: String?) -> Task? {
        return Task(inList: self, withTitle: title, withImage: image, withContentType: contentType)
    }
}