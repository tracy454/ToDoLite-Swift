//
//  MasterViewController.swift
//  ToDoLite-Swift
//
//  Created by Mark Tracy on 7/8/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//
//  Ported from CouchbaseLite demo app ToDoLite for iOS
//  MasterViewController.h and MasterViewController.m
//  Created by Chris Anderson on 11/14/13.
//  Copyright (c) 2013 Chris Anderson. All rights reserved.

import UIKit

typealias AppDelegateType = AppDelegate

class MasterViewController: UITableViewController, CBLUITableDelegate, UIAlertViewDelegate {

    var detailViewController: DetailViewController?
    @IBOutlet weak var dataSource: CBLUITableSource!
    var objects = NSMutableArray()
    var database: CBLDatabase!
    var app: AppDelegate!

//    override func awakeFromNib() {
//        super.awakeFromNib()
//        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
//            self.clearsSelectionOnViewWillAppear = false
//            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
//        }
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // database stuff
        app = UIApplication.sharedApplication().delegate as AppDelegate
        database = app.database
        let liveListQuery = List.queryListsInDatabase(database)?.asLiveQuery()
        dataSource!.query = liveListQuery
        dataSource!.labelProperty = "title"
        
        // login stuff
        if !app.cblSync.userID {
            var loginButton = UIBarButtonItem(title: "Login", style: .Bordered, target: self, action: "doLogin:")
            navigationItem.leftBarButtonItem = loginButton
        }
        
        // navigation stuff
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: CBL data
    @IBAction func doLogin(sender: AnyObject) {
        app.loginAndSync({
            println("called loginAndSync complete")
            })
    }

    func insertNewObject(sender: AnyObject) {
        let newListAlert = UIAlertView(title: "New To-Do List",
            message: "Title for new list:",
            delegate: self,
            cancelButtonTitle: "Cancel",
            otherButtonTitles: "Create")
        newListAlert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        newListAlert.show()
    }
    
    func createListWithTitle(title: String) -> List? {
        var list = List(inDatabase: database, withTitle: title)
        var myUser: Profile?
        if app.cblSync.userID {
            myUser = Profile(inDatabase: database, forUserID: app.cblSync.userID)
            list.owner = myUser
        }
        var error: NSError?
        if list.save(&error) == false {
            let alert = UIAlertView(title: "Error", message: "Unable to create a new list.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            return nil
        }
        return list
    }

    func alertView(alertView: UIAlertView!, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex > 0 {
            let title = alertView.textFieldAtIndex(0).text
            if !title.isEmpty {
                let list = createListWithTitle(title)
                tableView.reloadData()
            }
        }
    }
    
    //MARK: Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            let indexPath = self.tableView.indexPathForSelectedRow()
            let row = dataSource.rowAtIndex(UInt(indexPath.row))
            var list = CBLModel(forDocument: row.document) as? List
            ((segue.destinationViewController as UINavigationController).topViewController as DetailViewController).detailItem = list
        }
    }
    
    // CBLUITableDelegate
    func couchTableSource(source: CBLUITableSource!, updateFromQuery query: CBLLiveQuery!, previousRows: [AnyObject]!)  {
        tableView.reloadData()
    }

    //MARK: Table View
/*  CBLUITable handles these next four methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        let object = objects[indexPath.row] as NSDate
        cell.textLabel.text = object.description
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeObjectAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
*/
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            //let object = objects[indexPath.row] as NSDate
            //self.detailViewController!.detailItem = object
            let row = dataSource.rowAtIndex(UInt(indexPath.row))
            var list = CBLModel(forDocument: row.document)
            detailViewController!.detailItem = list
        } else {
            performSegueWithIdentifier("showDetail", sender: self)
        }
    }


}

