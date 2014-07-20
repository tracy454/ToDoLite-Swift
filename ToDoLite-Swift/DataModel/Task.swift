//
//  Task.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/11/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  Task.h and Task.m
//  Created by Jens Alfke on 8/22/13.

import Foundation

let kTaskDocType = "task"

class Task: Titled {
    var checked: Bool = false
    weak var list_id: List?
    
    override var docType: String {
    get{
        return kTaskDocType
    }
    }
    
    init(inList list: List, withTitle title: String,  withImage image: NSData?, withContentType contentType: String?) {
        list_id = list
        let database = list.document.database
        super.init(inDatabase: database, withTitle: title)
        if image {
            setAttachmentNamed("image", withContentType: contentType, content: image)
        }
    }
    
    func setImage(image: NSData, contentType: String) {
        setAttachmentNamed("image", withContentType: contentType, content: image)
    }
}