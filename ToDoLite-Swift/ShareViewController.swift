//
//  ShareViewController.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/9/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  ShareViewController.h and ShareViewController.m
//  Created by Chris Anderson on 11/14/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.

import UIKit

class ShareViewController: UIViewController, CBLUITableDelegate {

    @IBOutlet var tableView: UITableView
    @IBOutlet var dataSource: CBLUITableSource
    var list: List? {
    didSet {
        self.configureView()
    }
    }
    
    var database: CBLDatabase?
    var app: AppDelegate!
    var myDocId: String?
    
    override func viewDidLoad() {
        app = UIApplication.sharedApplication().delegate as AppDelegate
        database = app.database
        myDocId = "p:\(app.cblSync.userID)"
        
        super.viewDidLoad()
        
        self.configureView()

        // Do any additional setup after loading the view.
        if dataSource {
            
        }
    }
    
    func configureView() {
        dataSource.query = Profile.queryProfilesInDatabase(database).asLiveQuery()
        dataSource.labelProperty = "name"
    }
    
    // CBLUITableDelegate
    func couchTableSource(source: CBLUITableSource!,
        willUseCell cell: UITableViewCell!,
        forRow row: CBLQueryRow!) {
        let personId = row.document.documentID
        var member: Bool = false
        if myDocId == personId {
            member = true
        } else {
            var intersection = NSMutableSet(array: list?.members)
            intersection.intersectSet(NSSet(object: personId))
            if intersection.count > 0 {
                member = true
            }
        }
        if member {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        
    }
    
    func tableView(UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let row = dataSource.rowAtIndex(indexPath.row)
        let toggleMemberId = row.document.documentID
        var ms: NSArray? = list?.members
        if !ms {
            ms = NSArray()
        }
        let mss = ms!.componentsJoinedByString(" ")
        println("toggle: \(toggleMemberId)\nin members: \(mss)")
        
        let ndx = ms?.indexOfObject(toggleMemberId)
        if ndx {  // remove it
            let p = NSPredicate(format: "SELF != %@", argumentArray: [toggleMemberId])
            list!.members = ms!.filteredArrayUsingPredicate(p)
        } else {  // add it
            list!.members = ms!.arrayByAddingObject(toggleMemberId)
        }
        
        var error: NSError?
        if list!.save(&error) == false {
            println("Error saving list members: \(error?.localizedDescription)")
        }
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // #pragma mark - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
